//
//  MemoDetailViewController.swift
//  memo_app
//
//  Created by jinho on 2020/02/10.
//  Copyright © 2020 jinho. All rights reserved.
//
/* 메모의 상세 보기 화면 뷰 입니다. 보기 기능과 작성 기능을 합니다. */
import UIKit

class MemoViewContoller: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    /* 아래의 변수는 컨트롤러를 재활용할 때, imagePicker등의 내부에서 작동하게 되는 View들에 의해
     viewWillApear의 동작을 또 다시 하지 않게 하기 위한 변수입니다. */
    var needInitialize = true
    
    /* 포토 뷰어 정의*/
    /* 사용되지 않을 수 있어 lazy 생성 */
    lazy var photoViewerViewController = {
        return PhotoViewerViewController(collectionViewLayout: UICollectionViewFlowLayout())
    }()
    
    /* 이미지 피커 정의 */
    var imagePicker = UIImagePickerController()
    
    /* 필요한 의존성 매니저 생성 */
    let imageFileManager = ImageFileManager()
    let httpManager = HttpManager()
    let imageEditTools = ImageEditTools()
    
    /* 이미지 모델 생성 */
    var memo = Memo()
    
    /* photos 리스트의 값과 memo의 값이 다를 수 있습니다.
     실제로 memo 안의 photos는 메모가 Done 버튼을 통해 저장될 때만, 업데이트 되며,
     이 photos는 뷰의 상태 표시와 업데이트를 위한 것입니다.
     savedPhoto는 영구 저장소에 저장된 이미지를 의미합니다.
     */
    var photos: [Photo] = []
    var savedPhotoCount = 0
    var savedPhotoIdMax = 0
    
    /* 뷰에 재 진입 할 때, 뷰를 최상단으로 올리기 위한 y offset입니다.*/
    var headerYoffset: CGFloat?
    
    /* 이미지의 값이 실제로 영구 저장소에 올라가있지 않을 수 있습니다.
     Save 될 때만, 저장되지 않은 이미지가 올라갑니다. */
    var cachedImages = NSCache<NSString, UIImage>() // NSCache는 스레드 세이프 함.
    var thumbnailTemporaryImages = [Int : UIImage]()
    var imagesIndex = [Int]() // 저장되지 않은 이미지의 인덱스를 매칭합니다.
    
    let thumbnailImageSaveQueue = DispatchQueue(label: "resizeImageSave")
    let originalImageSaveQueue = DispatchQueue(label: "originalImageSave")
    
    /*
     뷰의 상태 | enableWriteLayout | isFirstWrite
     처음 작성 | true              | true
     글을 수정 | true              | false
     글을 본다 | false             | false
     */
    var enableWriteLayout: Bool = false // 작성, 수정 레이아웃 여부와 관련됩니다.
    var isFirstWrite: Bool = false // enableWriteLayout이고, 처음 작성 시 DB 저장 여부와 관련됩니다.
    
    /* 컬렉션 뷰의 헤더가 보이는지 아닌지 여부를 저장합니다. 이미지 컬렉션을 스크롤 했을 때, 추가 버튼이 보이지 않으면,
     네비게이션 바에 버튼으로 추가해서 보여주기 위해 이용합니다. */
    var collectionViewHeaderNotVisible = false
    
    /* 네비게이션 바에 추가되는 버튼 아이템 리스트 입니다. */
    var barItemEdit = UIBarButtonItem()
    var barItemInfo = UIBarButtonItem()
    var barItemSave = UIBarButtonItem()
    var barItemDelete = UIBarButtonItem()
    var barItemAddPhoto = UIBarButtonItem()
    
    /* 헤더의 텍스트 뷰들로 부터 값을 전달 받습니다. */
    var titleText = ""
    var contentText = ""
    
    /* 컬렉션 뷰의 레이아웃 엘리먼트 입니다. */
    let layout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        return layout
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.backgroundColor = .white
        
        layout.headerReferenceSize = CGSize(width: collectionView.frame.width, height: 50)
        layout.sectionInset = UIEdgeInsets(top: 2.5, left: 10, bottom: 2.5, right: 10)
        layout.minimumInteritemSpacing = 5
        layout.minimumLineSpacing = 5
        
        collectionView.collectionViewLayout = layout
        collectionView.dataSource = self
        collectionView.delegate = self
        
        imagePicker.delegate = self
        
        collectionView.collectionViewLayout.invalidateLayout()
        
        /* 이미지 셀 입니다.
         딜리트 버튼의 셀과 구분되어 있습니다.*/
        collectionView.register(MemoPhotoItemCellView.self, forCellWithReuseIdentifier: "imageForDelete")
        collectionView.register(MemoPhotoItemCellView.self, forCellWithReuseIdentifier: "image")
        /* 헤더 셀 입니다.*/
        collectionView.register(MemoHeaderCellView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "memoHeaderCellView")
        
        /* 네비게이션 바 컨트롤러의 버튼을 생성합니다. */
        barItemEdit = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(layoutToEditMode))
        
        let infoButton = UIButton(type: .infoDark)
        infoButton.addTarget(self, action: #selector(showInfo), for: .touchUpInside)
        infoButton.frame = CGRect(x: 0, y: 0, width: 50, height: infoButton.frame.height)
        barItemInfo = UIBarButtonItem(customView: infoButton)
        
        // Edit 모드는 상황에 따라 세 개의 아이템 목록을 혼합하여 사용합니다.
        barItemSave = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(editModeIsDone))
        
        barItemDelete = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteMemoConform))
        
        barItemAddPhoto = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(imageAddButtonActionSheet))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // 뷰 재호출 시에 뷰를 초기화 합니다.
        if needInitialize {
            initializeView()
            needInitialize = false
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if headerYoffset == nil {
            // 스크롤을 제일 위로 옮깁니다.https://stackoverflow.com/questions/22100227/scroll-uicollectionview-to-section-header-view
            // 이를 위해 헤더 오프셋 값을 가져올 필요가 있습니다.
            if let attributes = collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: [0, 0]) {
                var offsetY = attributes.frame.origin.y - collectionView.contentInset.top
                if #available(iOS 11.0, *) {
                    offsetY -= collectionView.safeAreaInsets.top
                }
                headerYoffset = offsetY
            }
        }
        
        // 뷰의 Y를 최상단으로 옮깁니다.
        // iOS 10
        if #available(iOS 11.0, *) {
        } else {
            if let offset = headerYoffset {
                collectionView.setContentOffset(CGPoint(x: 0, y: offset), animated: false)
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if isMovingFromParent {
            clearViewData()
            needInitialize = true
        }
    }
    
    func initializeView() {
        collectionView.reloadData() // 데이터 소거 후, 리로드 하지 않으면 iOS10에서 호환성 문제 발생함.\
        
        titleText = memo.title
        contentText = memo.content
        
        // 뷰의 Y를 최상단으로 옮깁니다.
        // iOS 11 이상
        if #available(iOS 11.0, *) {
            if let offset = headerYoffset {
                collectionView.setContentOffset(CGPoint(x: 0, y: offset), animated: false)
            }
        }
        
        collectionViewHeaderNotVisible = false
        
        for photo in memo.photos {
            photos.append(photo)
        }
        
        savedPhotoCount = photos.count
        savedPhotoIdMax = photos.last?.id ?? -1
        
        /* 뷰의 상태에 맞게 뷰를 갱신합니다. */
        /* 실제로 뷰 호출시에는 첫 글 쓰기, 또는 보기 모드이므로 두 가지 경우에만 해당합니다. */
        if isFirstWrite && enableWriteLayout {
            changeToFisrtWritingMode()
        } else if (!isFirstWrite && !enableWriteLayout) {
            changeToViewMode()
        }
    }
    
    func clearViewData() {
        // 임시 저장된 원본 데이터를 지웁니다.
        if imagesIndex.count > 0 {
            do {
                try imageFileManager.clearDirectory(directory: .originalTemporary)
            } catch {
                print(error)
            }
        }
        
        // 재 사용을 위한 데이터 제거
        photos.removeAll()
        cachedImages.removeAllObjects()
        thumbnailTemporaryImages.removeAll()
        imagesIndex.removeAll()
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    /* 컬렉션 뷰의 헤더 설정 (텍스트 작성란) */
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "memoHeaderCellView", for: indexPath) as! MemoHeaderCellView
            
            headerView.textView.text = contentText
            headerView.titleView.text = titleText
            
            //텍스트 뷰의 변화에 따라 레이아웃의 크기를 반영하기 위해 딜리게이트를 설정합니다.
            headerView.textView.delegate = self
            headerView.titleView.delegate = self
            
            //text 데이터 삽입한 레이아웃을 반영합니다.
            headerView.setNeedsLayout()
            headerView.layoutIfNeeded()
            
            /* 참고: 초기 didviewloadid에서 마지막의 이미지 라벨과 add 버튼이 있는 스택 뷰 보다 높이를 작게 지정하면, 레이아웃 크기가 맨 처음에 적게 산정되는 문제가 있습니다. */
            let calculatedHeight = headerView.verticalStackView.subviews
                .map({
                    $0.sizeThatFits(CGSize(width: $0.frame.width, height: CGFloat.infinity)).height
                })
                .reduce(0, {$0 + $1})
            
            layout.headerReferenceSize = CGSize(width: view.frame.width, height: calculatedHeight)
            
            /* 헤더 뷰의 컨텐츠가 레이아웃 모드를 따라갈 수 있도록 합니다. */
            if enableWriteLayout {
                headerView.textView.isEditable = true
                headerView.textView.accessibilityLabel = "Editable Text Input Form".localized()
                headerView.titleView.isEditable = true
                headerView.titleView.accessibilityLabel = "Editable Title Input Form".localized()
                headerView.imageCollectionBarAddButton.isHidden = false
            } else if (!isFirstWrite && !enableWriteLayout) {
                headerView.textView.isEditable = false
                headerView.textView.accessibilityLabel = "Text Content".localized()
                headerView.titleView.isEditable = false
                headerView.titleView.accessibilityLabel = "Title".localized()
                headerView.imageCollectionBarAddButton.isHidden = true
            }
            headerView.imageCollectionBarAddButton.addTarget(self, action: #selector(imageAddButtonActionSheet) , for: .touchUpInside)
            
            // 높이 변화를 반영합니다. (호출하지 않으면, 메모를 옮겨갈 때 높이가 반영되지 않을 수 있습니다.)
            headerView.setNeedsLayout()
            headerView.layoutSubviews()
            
            return headerView
        default:
            assert(false, "Unexpected element kind")
        }
    }
    
    /* 컬렉션 뷰의 셀 설정 (이미지) */
    /* 중요 : 오토 레이아웃 에러 발생
     Edit 모드로 변화할 때는 , delete 버튼이 추가 되서 보이는 셀이 늘어나지 않는데,
     View 모드로 바꿀 떄는 delete 버튼이 없어지면서 보이는 셀이 추가로 생겨서 레이아웃 고침 에러가 표시됨.
     보이지 않는 셀 까지 리로드 하면 해결 할 수 있으나, 성능 문제가 있을 것 같음. */
    //공부 : 셀이 리유즈 되므로, 셀을 async 하게 이미지 업데이트하면 의도하지 않은 결과가 나올 수 있음.
    //아이폰이 빨라서 문제가 없는 것 처럼 보이기도 하고, 심지어 스택에 비동기로 업데이트하는 코드를 올려놓기도 했는데 안 좋은 것 같음.
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if !enableWriteLayout {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "image", for: indexPath) as! MemoPhotoItemCellView
            
            if let image = getCollectionViewCache(indexPath: indexPath) {
                cell.imageView.image = image
            }
            
            cell.deleteButton.isHidden = true
            cell.heightAnchor.constraint(equalToConstant: 150).isActive = true
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageForDelete", for: indexPath) as! MemoPhotoItemCellView
            
            if let image = getCollectionViewCache(indexPath: indexPath) {
                cell.imageView.image = image
            }
            
            cell.deleteButton.indexPath = indexPath
            cell.deleteButton.addTarget(self, action: #selector(imageDelete(senderButton:)), for: .touchUpInside)
            cell.deleteButton.isHidden = false
            cell.heightAnchor.constraint(equalToConstant: 200).isActive = true
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if !enableWriteLayout {
            return CGSize(width: self.view.frame.width / 2 - 15, height: 150)
        } else {
            return CGSize(width: self.view.frame.width / 2 - 15, height: 200)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if !enableWriteLayout {
            photoViewerViewController.photos = photos
            photoViewerViewController.photoOffset = indexPath
            navigationController?.pushViewController(photoViewerViewController, animated: true)
        }
    }
}

/* 스크롤 뷰 속성과 관련 있는 함수 */
extension MemoViewContoller {
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: [0, 0]) != nil) {
            //컬렉션 헤더 뷰가 보이는 상태입니다.
            //네비게이션 바 아이템에 사진 추가 버튼이 없어야 합니다.
            if collectionViewHeaderNotVisible {
                collectionViewHeaderNotVisible = false
                if enableWriteLayout {
                    navigationItem.rightBarButtonItems?.remove(at: 1)
                }
            }
        } else {
            //컬렉션 헤더 뷰가 보이지 않는 상태입니다.
            //네비게이션 바에 사진 추가 버튼이 있어야 합니다.
            if !collectionViewHeaderNotVisible {
                collectionViewHeaderNotVisible = true
                if enableWriteLayout {
                    navigationItem.rightBarButtonItems?.insert(barItemAddPhoto, at: 1)
                }
            }
        }
    }
}

/* 캐시와 관련 있는 함수 */
extension MemoViewContoller {
    func getCollectionViewCache(indexPath: IndexPath) -> UIImage? {
        if indexPath.item < savedPhotoCount { // 영원하게 저장되어 있는 경우
            let idValue = String(photos[indexPath.item].id)
            
            if let cachedImage = cachedImages.object(forKey: idValue as NSString) { // 캐시에 저장되어 있음
                return cachedImage
            }
            
            let url = photos[indexPath.item].url
            if let cachedImage = self.imageFileManager.getSavedImage(named: url, directory: .thumbnail) {
                DispatchQueue.global().async {
                    self.cachedImages.setObject(cachedImage, forKey: idValue as NSString)
                }
                return cachedImage
            }
        } else {
            // 임시로 저장되어 있는 경우
            if indexPath.item - savedPhotoCount < imagesIndex.count, let thumbnailImage = thumbnailTemporaryImages[imagesIndex[indexPath.item - savedPhotoCount]] {
                // 임시 저장은 이미 메모리에 올라가 있으므로, 바로 반환함.
                return thumbnailImage
            }
        }
        print("Can not find image cache!")
        // 데이터를 찾을 수 없는 경우
        return UIImage(imageLiteralResourceName: "imageError") // 이미지 없음 표시
    }
}

/* 아래의 extension은 뷰의 변화와 관련된 함수들의 집합입니다. */
extension MemoViewContoller {
    /* 보이는 셀만 새로 그립니다. */
    func renderMemoPhotoItemCell() { //함수이름 render collectionview로 바꾸기
        collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems) // 보이는 셀만 버튼 추가해서 새로 그림
        layout.invalidateLayout()
    }
    
    /* 뷰를 호출하기 전에 View의 모습을 설정할 수 있도록, 변수를 변경하는 함수입니다. */
    func setToFirstWriteMode() {
        isFirstWrite = true
        enableWriteLayout = true
    }
    
    func setToViewMode() {
        isFirstWrite = false
        enableWriteLayout = false
    }
    
    /* 뷰가 호출된 이후에, 글 작성, 보기 모드 간의 변환을 위한 메서드입니다. */
    func changeToFisrtWritingMode() {
        isFirstWrite = true
        layoutToEditMode()
    }
    
    func changeToViewMode() {
        isFirstWrite = false
        layoutToViewMode()
    }
    
    @objc func layoutToEditMode() {
        enableWriteLayout = true
        
        //아래의 함수는 뷰의 어피어 시점에서는 적용되지 않습니다. (헤더뷰 생성전)
        //실행 후 버튼을 통했을 때의 변화를 제어합니다.
        if let headerView = collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: [0, 0]) as? MemoHeaderCellView {
            headerView.textView.isEditable = true
            headerView.textView.accessibilityLabel = "Editable Text Input Form".localized()
            headerView.titleView.isEditable = true
            headerView.titleView.accessibilityLabel = "Editable Title Input Form".localized()
            headerView.imageCollectionBarAddButton.isHidden = false
            headerView.layoutSubviews()
            headerView.layoutSublayers(of: .init())
        }
        
        renderMemoPhotoItemCell()
        changeRightNavigationItemToEditMode()
    }
    
    @objc func layoutToViewMode() {
        enableWriteLayout = false // 중복 설정되는 부분 있음 유의할 것
        
        //아래의 함수는 뷰의 어피어 시점에서는 적용되지 않습니다. (헤더뷰 생성전)
        //실행 후 버튼을 통했을 때의 변화를 제어합니다.
        if let headerView = collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: [0, 0]) as? MemoHeaderCellView {
            headerView.textView.isEditable = false
            headerView.textView.accessibilityLabel = "Text Content".localized()
            headerView.titleView.isEditable = false
            headerView.titleView.accessibilityLabel = "Title".localized()
            headerView.imageCollectionBarAddButton.isHidden = true
            headerView.layoutSubviews()
            headerView.layoutSublayers(of: .init())
        }
        
        renderMemoPhotoItemCell()
        changeRightNavigationItemToViewMode()
    }
    
    @objc func editModeIsDone() {
        collectionView.endEditing(true) //Done 버튼을 클릭하면 textView의 endEditing delegate function이 호출될 수 있도록 합니다. (변수에 값이 저장되어야 함.)
        
        if isFirstWrite { // 처음 작성
            saveMemo()
        } else { // 있던 글 편집
            editMemo()
        }
        
        // 영구 저장하는 동안 시간이 걸릴 수 있으므로, 대기 알럿을 표출합니다.
        self.showWatingAlert(title: "Saving".localized(), height: 100) { alert in
            // 알럿이 표시된 후 저장합니다.
            self.savePhotosPermanently()
            // 저장이 끝나 알럿을 지웁니다.
            alert.dismiss(animated: true) {
                // 알럿을 지운 후 레이아웃을 갱신합니다.
                self.layoutToViewMode()
                self.changeRightNavigationItemToViewMode()
            }
        }

    }
    
    
    func changeRightNavigationItemToViewMode() {
        navigationItem.rightBarButtonItems = [barItemEdit, barItemInfo]
    }
    
    func changeRightNavigationItemToEditMode() {
        if isFirstWrite {
            navigationItem.rightBarButtonItems = [barItemSave]
        } else {
            navigationItem.rightBarButtonItems = [barItemSave, barItemDelete]
        }
        if collectionViewHeaderNotVisible {
            navigationItem.rightBarButtonItems?.insert(barItemAddPhoto, at: 1)
        }
    }
    
    @objc func deleteMemoConform() {
        let actionSheet = UIAlertController(title: nil, message: "Are you really want to delete?".localized(), preferredStyle: .actionSheet)
        
        let deleteAction = UIAlertAction(title: "Delete".localized(), style: .default, handler: {_ in
            // 지우는 시간이 오래 걸릴 수 있으므로 알럿을 띄웁니다.
            self.showWatingAlert(title: "Deleting".localized(), height: 100) { alert in
                self.deleteMemo()
                // 저장이 끝나 알럿을 지웁니다.
                alert.dismiss(animated: true, completion: {
                    //리스트로 이동합니다.
                    self.dismissView()
                })
            }
        })
        let cancelAcion = UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil)
        
        actionSheet.addAction(deleteAction)
        actionSheet.addAction(cancelAcion)
        
        present(actionSheet, animated: true, completion: nil)
        
    }
    
    /* 이미지 Add 버튼을 눌렀을 때 호출되는 액션 시트입니다. */
    @objc func imageAddButtonActionSheet() {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let cameraAction = UIAlertAction(title: "Camera".localized(), style: .default, handler: {_ in self.openCamera()})
        let cameraRollAction = UIAlertAction(title: "CameraRoll".localized(), style: .default, handler: {_ in self.openCameraRoll()})
        let imageFromUrlAction = UIAlertAction(title: "URL", style: .default, handler: {_ in self.downloadAlert()})
        let cancelAcion = UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil)
        
        actionSheet.addAction(cameraAction)
        actionSheet.addAction(cameraRollAction)
        actionSheet.addAction(imageFromUrlAction)
        actionSheet.addAction(cancelAcion)
        
        present(actionSheet, animated: true, completion: nil)
    }
    
    func showWatingAlert(title: String?, height: CGFloat, complition: @escaping(UIAlertController) -> ()) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        
        let verticalContraint = alert.view.heightAnchor.constraint(equalToConstant: height)
        verticalContraint.isActive = true
        
        // To do: indicator 위치가 맘에 안 듦.
        let indicator = UIActivityIndicatorView(frame: alert.view.bounds)
        indicator.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        alert.view.addSubview(indicator)
        indicator.isUserInteractionEnabled = false
        indicator.startAnimating()
        
        present(alert, animated: true, completion: { complition(alert) })
        
        //return alert
    }
}

/* 아래의 extension은 데이터 처리와 관련이 있는 함수들의 모임입니다. */
extension MemoViewContoller {
    /* 메모 텍스트 데이터 처리와 연관된 메소드입니다. */
    /* 데이터 베이스에 새로운 메모를 추가하고, 처음 작성 모드를 끝냅니다. */
    func saveMemo() {
        memo.title = titleText
        memo.content = contentText
        memo.id = (RealmManager.realm.objects(Memo.self).max(ofProperty: "id") as Int? ?? -1) + 1
        memo.editDate = Date()
        memo.createDate = Date()
        RealmManager.write(realm: RealmManager.realm) {
            RealmManager.realm.add(memo)
        }
        
        if isFirstWrite { isFirstWrite = false }
    }
    
    /* 데이터 베이스의 메모를 수정합니다. */
    func editMemo() {
        RealmManager.write(realm: RealmManager.realm) {
            memo.title = titleText
            memo.content = contentText
            memo.editDate = Date()
        }
    }
    
    /* 메모 이미지 데이터 처리와 연관된 메소드입니다. */
    /* 아래의 메소드는 컨트롤러에 메모리를 임시로 합니다.
     사용자가 Done 버튼을 누르지 않으면 내용은 영구적으로는 반영되지 않습니다.*/
    /* 오리지날 이미지는 메모리에 올리기엔 너무 클 수 있으므로,
     temporary filefh 먼저 영구 저장한 다음 처리합니다.*/
    func savePhotoTemporary(image: UIImage) {
        photos.append(Photo())
        
        let index = (imagesIndex.last ?? -1) + 1
        imagesIndex.append(index)
        
        // 오리지날 이미지를 임시 저장합니다.
        originalImageSaveQueue.async {
            do {
                let rotatedImage = self.imageEditTools.rotateImage(image: image)
                let imageData = try self.imageEditTools.uiimageToFileData(image: rotatedImage)
                try self.imageFileManager.saveImage(imageName: String(index), imageData: imageData, directory: .originalTemporary)
            } catch {
                print(error)
            }
        }
        
      //  let idValue = String(savedPhotoIdMax + 1 + index)
        
      //  self.cachedImages.setObject(image, forKey: idValue as NSString)
        
        DispatchQueue.global().async {
            guard let resizedImage = self.imageEditTools.resizeImage(image: image, toWidth: 400) else {
                print("Image resizing fail!")
                return
            }
            
            guard let thumbnailImage = self.imageEditTools.rotateImage(image: resizedImage) else {
                print("Image rotating fail!")
                return
            }
            
            self.thumbnailImageSaveQueue.async {
                self.thumbnailTemporaryImages[index] = thumbnailImage
              //  self.cachedImages.setObject(thumbnailImage, forKey: idValue as NSString)
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
            }
        }
    }
    
    /* 메모리에서 이미지를 지우는 함수입니다. delete 버튼과 연동됩니다. */
    /* 영구적으로 저장된 이미지를 지우는 작업은 savePhotoPermanently 메소드에서 진행합니다. */
    @objc func imageDelete(senderButton: UIButton) {
        if let button = senderButton as? ButtonWithIndexPath {
            if let index = button.indexPath?.item {
                let idValue = String(photos[index].id)
                photos.remove(at: index)
                
                if savedPhotoCount <= index { // 영구 메모리에 저장되지 않은 경우
                    print("delete not permanent \(index)")
                    let removeImageIndex = imagesIndex[index - savedPhotoCount]
                    
                    //이미지 인덱스를 리사이즈드 이미지 세이브 큐 안에서 삭제하지 않으면 참조 오류가 발생할 수 있습니다. (순서 문제 발생 가능)
                    let willDeleteIndexValue = index - savedPhotoCount
                    thumbnailImageSaveQueue.async {
                        self.imagesIndex.remove(at: willDeleteIndexValue)
                    }
                    
                 //   idValue = String(savedPhotoIdMax + 1 + removeImageIndex)
                    
                    thumbnailImageSaveQueue.async { // resizedImage는 해당 큐에서 관리되어야 합니다.
                        // 결과를 바로 이용할 필요가 없습니다.
                        self.thumbnailTemporaryImages.removeValue(forKey: removeImageIndex)
                    }
                } else { // 영구 메모리에 저장된 경우
                    print("delete permanent \(index)")
                    savedPhotoCount -= 1
                    cachedImages.removeObject(forKey: idValue as NSString)
                }
                
        //        cachedImages.removeObject(forKey: idValue as NSString)
                
                collectionView.reloadData()
            }
        }
    }
    
    /* 아래의 메소드는 컨트롤러의 임시 사진 데이터와 실제 데이터를 동기화 처리합니다.
     사진이 저장되거나, 삭제 됩니다.
     사용자가 Done 버튼을 누르면 반드시 호출되어야 하는 메소드입니다.
     해당 함수의 시간 복잡도는 최대 O(임시 카운트 + 영구 저장 사진 카운트)이므로 선형의 복잡도를 가집니다.
     */
    func savePhotosPermanently() {
        var temporaryCount = 0 // temporary 이미지에 대한 인덱스입니다.
        var permanentlyCount = 0 // 영구 저장 이미지에 대한 인덱스입니다.
        
        thumbnailImageSaveQueue.sync { } // 이미지 리사이징이 끝날 때 까지 대기합니다.
        originalImageSaveQueue.sync { } // 오리지날 이미지 저장이 끝날 때 까지 대기합니다.
        
        while temporaryCount < photos.count || permanentlyCount < memo.photos.count {
            if temporaryCount == photos.count {
                // 뒤에 있는 이미지를 모두 지웁니다.
                let deleteAmount = memo.photos.count - permanentlyCount
                for _ in (0..<deleteAmount) {
                    let imageUrl = memo.photos[memo.photos.count - 1].url
                    RealmManager.write(realm: RealmManager.realm) {
                        RealmManager.realm.delete(memo.photos[memo.photos.count - 1])
                    }
                    // File 제거
                    do {
                        try imageFileManager.deleteImage(imageName: imageUrl, directory: .thumbnail)
                        try imageFileManager.deleteImage(imageName: imageUrl, directory: .original)
                    } catch {
                        print(error)
                    }
                }
                break
            }
            if permanentlyCount == memo.photos.count || photos[temporaryCount].id == -1 {
                // 뒤에 있는 이미지를 모조리 추가합니다.
                let baseId = (RealmManager.realm.objects(Photo.self).max(ofProperty: "id") as Int? ?? -1) + 1 - temporaryCount
                
                while temporaryCount < photos.count {
                    photos[temporaryCount].id = baseId + temporaryCount
                    photos[temporaryCount].url = String(baseId + temporaryCount)
                    
                    RealmManager.write(realm: RealmManager.realm) {
                        memo.photos.append(photos[temporaryCount])
                    }
                    
                    if let image = self.thumbnailTemporaryImages[imagesIndex[temporaryCount - self.savedPhotoCount]] {
                        do {
                            //썸네일을 저장합니다.
                            if let imageData = try? imageEditTools.uiimageToFileData(image: image) {
                                try self.imageFileManager.saveImage(imageName: photos[temporaryCount].url, imageData: imageData, directory: .thumbnail)
                            }
                            // 임시 저장 오리지날 이미지를 영구저장 폴더로 옮깁니다.
                            try self.imageFileManager.moveFromTo(from: .originalTemporary, fromImageName: String(imagesIndex[temporaryCount - self.savedPhotoCount]), to: .original, toImageName: photos[temporaryCount].url)
                        } catch {
                            print(error)
                        }
                    }
                    
                    temporaryCount += 1
                }
                break
            }
            
            if photos[temporaryCount].id == memo.photos[permanentlyCount].id {
                temporaryCount += 1
                permanentlyCount += 1
            } else if photos[temporaryCount].id > memo.photos[permanentlyCount].id {
                // 이미지를 지워야 합니다.
                let imageUrl = memo.photos[permanentlyCount].url
                RealmManager.write(realm: RealmManager.realm) {
                    RealmManager.realm.delete(memo.photos.filter("id == %@", memo.photos[permanentlyCount].id))
                }
                do {
                    try imageFileManager.deleteImage(imageName: imageUrl, directory: .original)
                    try imageFileManager.deleteImage(imageName: imageUrl, directory: .thumbnail)
                } catch {
                    print(error)
                }
            } else {
                // 항상 id가 단조증가 하므로 일어날 수 없는 동작입니다.
                print("Error occurd reflecting Photo!")
            }
        }
        
        // 저장 완료 후, 임시 디렉토리 클리어 작업 및 인덱스 조정 등을 실시합니다.
        do {
            try imageFileManager.clearDirectory(directory: .originalTemporary)
        } catch {
            print(error)
        }
        savedPhotoCount = photos.count
        savedPhotoIdMax = photos.last?.id ?? -1
        thumbnailTemporaryImages.removeAll()
        imagesIndex.removeAll()
    }
    
    /* delete 버튼을 클릭 했을 때, 메모의 모든 사진을 순회하여 삭제하고,
     메모 자체를 삭제한 후, 리스트 뷰로 되돌아 갑니다. */
    func deleteMemo() {
        for photo in memo.photos {
            do {
                try imageFileManager.deleteImage(imageName: photo.url, directory: .original)
                try imageFileManager.deleteImage(imageName: photo.url, directory: .thumbnail)
            } catch {
                print(error)
            }
        }
        
        RealmManager.write(realm: RealmManager.realm) {
            RealmManager.realm.delete(memo.photos)
            RealmManager.realm.delete(memo)
        }
        
        dismissView()
    }
}

/* 아래의 익스텐션은 Add 클릭 후 ActionSheet에서 URL을 클릭했을 때
 다운로드 동작과 관련되어 있습니다.*/
extension MemoViewContoller {
    func saveDownloadedImage(downloadedImage: UIImage?) {
        //이미지가 잘 못 되었을 경우 알려주고 종료
        //이미지가 정상일 경우 저장
        if let image = downloadedImage {
            savePhotoTemporary(image: image)
        } else {
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Error".localized(), message: "Not a Image".localized(), preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "OK".localized(), style: .cancel, handler: nil)
                
                alert.addAction(cancelAction)
                
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func downloadFromUrl(userUrl: String?) {
        //url 변환 및 url이 잘 못 되었을 경우 알려주고 종료
        guard let string = userUrl, let url = httpManager.stringToUrl(from: string) else {
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Error".localized(), message: "Incollect URL".localized(), preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "OK".localized(), style: .cancel, handler: nil)
                
                alert.addAction(cancelAction)
                
                self.present(alert, animated: true, completion: nil)
            }
            
            return
        }
        
        // 기다리는 동안 대기 alert을 호출합니다.
        DispatchQueue.main.async {
            // 이미지가 작을 경우 httpManager.getImage안의 클로저가 먼저 호출될 수 있으므로,
            // main에서 순차적으로 호출합니다.
            // url로 부터 이미지 요청
            self.showWatingAlert(title: "Downloading".localized(), height: 150) { alert in
                let task = self.httpManager.getImage(from: url, complition: { dataImage , error in
                        //에러가 존재합니다.
                        if let error = error as NSError? {
                            //사용자가 임의로 작업을 취소하였습니다. 더 이상 진행하지 않습니다.
                            if error.code == NSURLErrorCancelled {
                                return
                            }
                        }
                        // 완료된 작업
                        DispatchQueue.main.async {
                            alert.dismiss(animated: true, completion: {
                                self.saveDownloadedImage(downloadedImage: dataImage)
                            })
                        }
                    })
                    
                    // 취소 액션을 경고창에 포함합니다.
                    let cancelButton = UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: { _ in task.cancel() } )
                    alert.addAction(cancelButton)
                }
            }
    }
    
    func downloadAlert() {
        //URL 입력 받는 창 출력
        let alert = UIAlertController(title: nil, message: "Input URL at bellow text box".localized(), preferredStyle: .alert)
        let downloadAction = UIAlertAction(title: "Download".localized(), style: .default, handler: { _ in
            self.downloadFromUrl(userUrl: alert.textFields?[0].text)
        })
        let cancelAction = UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil)
        
        alert.addTextField(configurationHandler: { textfiled in
            textfiled.placeholder = "Input URL here".localized()
        })
        alert.addAction(downloadAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
}

/* 아래의 extension은 카메라 및 카메라 롤과 관련있는 모임입니다. */
extension MemoViewContoller: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    // ios13+ : View가 모달로 보여서 viewwillapear 호출을 안 함.
    // ios13- : View가 fullscreen이기 때문에 viewwillapear를 호출함.
    func openCameraRoll() {
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    func openCamera() {
        imagePicker.sourceType = .camera
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            savePhotoTemporary(image: image)
        } else {
            print("Image Picker Failed.")
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }
}

/* 아래의 extension은 textview로 부터 delegate를 받아 다이나믹하게 뷰의 크기를 변화시킵니다. */
extension MemoViewContoller: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        /* 컬렉션 뷰를 딜레게이트로 지정한 텍스트 뷰들에 대한 딜리게이트 함수를 시행합니다.
         컬렉션 뷰 헤더의 텍스트 뷰가 변화하면 높이를 계산하여, 레이아웃을 능동적으로 변화시킵니다.*/
        
        let calculatedHeight = textView.superview?.subviews
            .map({
                $0.sizeThatFits(CGSize(width: $0.frame.width, height: CGFloat.infinity)).height
            })
            .reduce(0, {$0 + $1})
        
        layout.headerReferenceSize = CGSize(width: view.frame.width, height: calculatedHeight ?? 50)
        
        layout.invalidateLayout()
        self.collectionView.layoutSubviews()
    }
    
    /* 텍스트 뷰의 editing이 끝나면 내용을 변수에 저장할 수 있도록 합니다.
     데이터 저장에 향후 이용됩니다. */
    func textViewDidEndEditing(_ textView: UITextView) {
        switch textView.tag {
        case 0:
            titleText = textView.text
        case 1:
            contentText = textView.text
        default:
            print("this kind of textView can not exist")
        }
    }
    
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        return true
    }
}

extension MemoViewContoller {
    /* 메보 보기 화면에서 동그란 i 아이콘을 클릭한다면, 메모의 정보를 보여줍니다. */
    @objc func showInfo() {
        let dateFormater = DateFormatter()
        dateFormater.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let message = "\("Created".localized()): \(dateFormater.string(from: memo.createDate))\n\("Updated".localized()): \(dateFormater.string(from: memo.editDate))\n\("Nomber of Photo".localized()): \(memo.photos.count)"
        let alert = UIAlertController(title: "Info".localized(), message: message, preferredStyle: .alert)
        let conformButton = UIAlertAction(title: "OK".localized(), style: .default, handler: nil)
        
        alert.addAction(conformButton)
        
        present(alert, animated: true, completion: nil)
        
    }
    
    /* 뷰를 없앰 */
    @objc func dismissView() {
        navigationController?.popViewController(animated: true)
    }
}
