//
//  MemoDetailViewController.swift
//  memo_app
//
//  Created by jinho on 2020/02/10.
//  Copyright © 2020 jinho. All rights reserved.
//
/* 메모의 상세 보기 화면 뷰 입니다. */
import UIKit

class MemoViewContoller: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    /* 아래의 변수는 컨트롤러를 재활용할 때, imagePicker등의 내부에서 작동하게 되는 View들에 의해
     viewWillApear의 동작을 또 다시 하지 않게 하기 위한 변수입니다. */
    var needInitialize = true
    
    var imagePicker = UIImagePickerController()
    
    let imageFileManager = ImageFileManager()
    
    let httpManager = HttpManager()
    
    //이미지 다운로드 시 UIActivityIndicator를 호출할 때 사용합니다.
    var watingIndicator: UIView?
    
    var memo = Memo()
    
    /* photos 리스트의 값과 memo의 값이 다를 수 있습니다.
     실제로 memo 안의 photos는 메모가 Done 버튼을 통해 저장될 때만, 업데이트 되며,
     이 photos는 뷰의 상태 표시와 업데이트를 위한 것입니다.
    */
    var photos: [Photo] = []
    var savedPhotoCount = 0
    var maxPhotoId = 0
    
    var indexPathToId = [Int: Int]()
    
    /* images의 값이 실제로 영구 저장소에 올라가있지 않을 수 있습니다.
     Done을 통해 Save 될 때만, 저장되지 않은 이미지가 올라갑니다. */
    //var images: [UIImage] = []
    var images = NSCache<NSString, UIImage>()
    var resizedImages = [Int : UIImage]()
    var imageIndex = [Int]()
    
    let resizedImageSaveQueue = DispatchQueue(label: "resizeImageSave")
    
    /*
     뷰의 상태 | enableWriteLayout | isFirstWrite
     처음 작성 | true              | true
     글을 수정 | true              | false
     글을 본다 | false             | false
     */
    var enableWriteLayout: Bool = false // 작성, 수정 레이아웃 여부와 관련됩니다.
    var isFirstWrite: Bool = false // enableWriteLayout이고, 처음 작성 시 DB 저장 여부와 관련됩니다.
    
    /* 헤더의 텍스트 뷰들로 부터 값을 전달 받습니다. */
    var titleText = ""
    var contentText = ""
    
    let layout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        return layout
    }()
    
    override func viewDidLoad() { // 근데 ? 붙여야 하던가?
        super.viewDidLoad()
        
        collectionView.backgroundColor = .white
        
        layout.headerReferenceSize = CGSize(width: collectionView.frame.width, height: 50)
        layout.sectionInset = UIEdgeInsets(top: 2.5, left: 10, bottom: 2.5, right: 10)
        layout.minimumInteritemSpacing = 0
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
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if needInitialize { initializeView() }
    }
    
    func initializeView() {
        titleText = memo.title
        contentText = memo.content

        photos.removeAll(keepingCapacity: false)
        //images.removeAll(keepingCapacity: false)
        collectionView.reloadData() // 데이터 소거 후, 리로드 하지 않으면 iOS10에서 호환성 문제 발생함.
        
        for photo in memo.photos {
            photos.append(photo)
            //images.append(imageFileManager.getSavedImage(named: photo.url) ?? UIImage())
        }
        
        images.removeAllObjects()
        resizedImages.removeAll()
        imageIndex.removeAll()
        
        savedPhotoCount = photos.count
        maxPhotoId = photos.last?.id ?? -1
        
        /* 뷰의 상태에 맞게 뷰를 갱신합니다. */
        /* 실제로 뷰 호출시에는 첫 글 쓰기, 또는 보기 모드이므로 두 가지 경우에만 해당합니다. */
        if isFirstWrite && enableWriteLayout {
            changeToFisrtWritingMode()
        } else if (!isFirstWrite && !enableWriteLayout) {
            changeToViewMode()
        }
        
        // 스크롤을 제일 위로 옮깁니다. https://stackoverflow.com/questions/22100227/scroll-uicollectionview-to-section-header-view
        if let attributes = collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: [0, 0]) {
            var offsetY = attributes.frame.origin.y - collectionView.contentInset.top
            if #available(iOS 11.0, *) {
                offsetY -= collectionView.safeAreaInsets.top
            }
            collectionView.setContentOffset(CGPoint(x: 0, y: offsetY), animated: false) // or animated: false
        }
        
        needInitialize = false
    }
    
    @objc func dismissView() {
        navigationController?.popViewController(animated: true)
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
                print(indexPath)
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

                /* 헤더 뷰 생성 시점에서의 수정 편접 가능을 설정합니다. */
                if isFirstWrite && enableWriteLayout {
                    headerView.textView.isEditable = true
                    headerView.titleView.isEditable = true
                    headerView.imageCollectionBarAddButton.isHidden = false
                } else if (!isFirstWrite && !enableWriteLayout) {
                    headerView.textView.isEditable = false
                    headerView.titleView.isEditable = false
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
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if !enableWriteLayout {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "image", for: indexPath) as! MemoPhotoItemCellView
            
            // indexPath를 사진의 URL로 교정합니다. (참고로 이미지 지우고 추가할 떄, 캐시 데이터 업데이트 하는 게 맞는 듯함.)
            var idValue = ""
            
            if indexPath.item < savedPhotoCount { // 영원하게 저장되어 있는 경우
                idValue = String(photos[indexPath.item].id)
            } else { // 임시로 저장된 경우
                idValue = String(maxPhotoId + 1 + imageIndex[indexPath.item - savedPhotoCount])
            }
            
            if images.object(forKey: idValue as NSString) == nil { // 캐시에 저장되어 있지 않은 경우
                if indexPath.item < savedPhotoCount { // 영원하게 저장되어 있는 경우
                    images.setObject(imageFileManager.getSavedImage(named: photos[indexPath.item].url) ?? UIImage(), forKey: idValue as NSString)
                } else { // 임시로 저장되어 있는 경우
                    if indexPath.item - savedPhotoCount < resizedImages.count, let resizedImage = resizedImages[imageIndex[indexPath.item - savedPhotoCount]] {
                        images.setObject(resizedImage, forKey: idValue as NSString)
                    }
                }
            }
            
            if let cachedImage = images.object(forKey: idValue as NSString) {
                cell.imageView.image = cachedImage
            }
            
            //cell.imageView.image = images[indexPath.item]
            cell.deleteButton.isHidden = true
            cell.heightAnchor.constraint(equalToConstant: 150).isActive = true
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageForDelete", for: indexPath) as! MemoPhotoItemCellView
            
            // indexPath를 사진의 URL로 교정합니다. (참고로 이미지 지우고 추가할 떄, 캐시 데이터 업데이트 하는 게 맞는 듯함.)
            var idValue = ""
            
            if indexPath.item < savedPhotoCount { // 영원하게 저장되어 있는 경우
                idValue = String(photos[indexPath.item].id)
            } else { // 임시로 저장된 경우
                idValue = String(maxPhotoId + 1 + imageIndex[indexPath.item - savedPhotoCount])
            }
            
            print(idValue)
            
            if images.object(forKey: idValue as NSString) == nil { // 캐시에 저장되어 있지 않은 경우
                if indexPath.item < savedPhotoCount { // 영원하게 저장되어 있는 경우
                    images.setObject(imageFileManager.getSavedImage(named: photos[indexPath.item].url) ?? UIImage(), forKey: idValue as NSString)
                } else { // 임시로 저장되어 있는 경우
                    if indexPath.item - savedPhotoCount < resizedImages.count, let resizedImage = resizedImages[imageIndex[indexPath.item - savedPhotoCount]] {
                        images.setObject(resizedImage, forKey: idValue as NSString)
                        print("호출되는지11111")
                    }
                }
            }
            
            if let cachedImage = images.object(forKey: idValue as NSString) {
                cell.imageView.image = cachedImage
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
            return CGSize(width: self.view.frame.width / 2 - 20, height: 150)
        } else {
            return CGSize(width: self.view.frame.width / 2 - 20, height: 200)
        }
    }
}

/* 아래의 extension은 뷰의 변화와 관련된 함수들의 집합입니다. */
extension MemoViewContoller {
    /* 보이는 셀만 새로 그립니다. */
    func renderMemoPhotoItemCell() {
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
    
    @objc func layoutToEditMode() { // 근데 왜 OBJC붙여야함? 전에도 왜인지 몰랐는뎅
        enableWriteLayout = true
        
        //아래의 함수는 뷰의 어피어 시점에서는 적용되지 않습니다. (헤더뷰 생성전)
        //실행 후 버튼을 통했을 때의 변화를 제어합니다.
        if let headerView = collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: [0, 0]) as? MemoHeaderCellView {
            headerView.textView.isEditable = true
            headerView.titleView.isEditable = true
            headerView.imageCollectionBarAddButton.isHidden = false
        }
        
        renderMemoPhotoItemCell()
        navigationItem.title = "Writing".localized()
        changeRightNavigationItemToDone()
    }
    
    @objc func layoutToViewMode() {
        enableWriteLayout = false // 중복 설정되는 부분 있음 유의할 것

        //아래의 함수는 뷰의 어피어 시점에서는 적용되지 않습니다. (헤더뷰 생성전)
        //실행 후 버튼을 통했을 때의 변화를 제어합니다.
        if let headerView = collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: [0, 0]) as? MemoHeaderCellView {
            headerView.textView.isEditable = false
            headerView.titleView.isEditable = false
            headerView.imageCollectionBarAddButton.isHidden = true
            
        }
        
        renderMemoPhotoItemCell()
        navigationItem.title = "Memo".localized()
        changeRightNavigationItemToEdit()
    }
    
    @objc func editModeIsDone() {
        collectionView.endEditing(true) //Done 버튼을 클릭하면 textView의 endEditing delegate function이 호출될 수 있도록 합니다. (변수에 값이 저장되어야 함.)
        
        if isFirstWrite { // 처음 작성
            saveMemo()
        } else { // 있던 글 편집
            editMemo()
        }
        
        reflectPhoto()
        
        layoutToViewMode()
        changeRightNavigationItemToEdit()
    }
    
    
    func changeRightNavigationItemToEdit() {
        navigationItem.rightBarButtonItems = [UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(layoutToEditMode))]
    }
    
    func changeRightNavigationItemToDone() {
        if isFirstWrite {
            navigationItem.rightBarButtonItems = [UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(editModeIsDone))]
        } else {
            navigationItem.rightBarButtonItems = [UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(editModeIsDone)), UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteMemoConform))]
        }
    }
    
    /* delete 버튼을 클릭 했을 때, 메모의 모든 사진을 순회하여 삭제하고,
     메모 자체를 삭제한 후, 리스트 뷰로 되돌아 갑니다. */
    func deleteMemo() {
        for photo in memo.photos {
            imageFileManager.deleteImage(imageName: photo.url)
        }
        
        RealmManager.write(realm: RealmManager.realm) {
            RealmManager.realm.delete(memo.photos)
            RealmManager.realm.delete(memo)
        }
        
        dismissView()
    }
    
    @objc func deleteMemoConform() {
        let actionSheet = UIAlertController(title: nil, message: "Are you really want to delete?".localized(), preferredStyle: .actionSheet)
        
        let deleteAction = UIAlertAction(title: "Delete".localized(), style: .default, handler: {_ in self.deleteMemo()})
        let cancelAcion = UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil)
        
        actionSheet.addAction(deleteAction)
        actionSheet.addAction(cancelAcion)
        
        present(actionSheet, animated: true, completion: nil)
        
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
        }
    }
    
    /* 메모 이미지 데이터 처리와 연관된 메소드입니다. */
    /* 아래의 메소드는 컨트롤러에 메모리를 임시로 합니다.
     사용자가 Done 버튼을 누르지 않으면 내용은 영구적으로는 반영되지 않습니다.*/
    func savePhotoTemporary(image: UIImage) {
        photos.append(Photo())
        //images.append(image)
        
        let index = (imageIndex.last ?? -1) + 1
        imageIndex.append(index)
        
        let idValue = String(maxPhotoId + 1 + index)
        
        self.images.setObject(image, forKey: idValue as NSString)
        
        DispatchQueue.global().async {
            if let resizedImage = self.imageFileManager.resizeImage(image: image, toWidth: 500) {
                print("돼는건지?", index)
                self.resizedImageSaveQueue.async {
                    self.resizedImages[index] = resizedImage
                    self.images.setObject(resizedImage, forKey: idValue as NSString)
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                    }
                }
            }
        }
        
        collectionView.reloadData()
    }
    
    /* 메모리에서 이미지를 지우는 함수입니다. delete 버튼과 연동됩니다. */
    @objc func imageDelete(senderButton: UIButton) {
        if let button = senderButton as? ButtonWithIndexPath {
            if let index = button.indexPath?.item {
                var idValue = String(photos[index].id)
                
                photos.remove(at: index)
                //images.remove(at~~)
                print(index)
                
                if savedPhotoCount - 1 < index { // 영구 메모리에 저장되지 않은 경우
                    let removeImageIndex = imageIndex[index - savedPhotoCount]
                    
                    //이미지 인덱스를 리사이즈드 이미지 세이브 큐 안에서 삭제하지 않으면 참조 오류가 발생할 수 있습니다. (순서 문제 발생 가능)
                    let willDeleteIndexValue = index - savedPhotoCount
                    resizedImageSaveQueue.async {
                        self.imageIndex.remove(at: willDeleteIndexValue)
                    }
                    
                    idValue = String(maxPhotoId + 1 + removeImageIndex)
                    
                    self.resizedImageSaveQueue.async {
                        self.resizedImages.removeValue(forKey: removeImageIndex)
                    }
                } else { // 영구 메모리에 저장된 경우
                    savedPhotoCount -= 1
                }
                
                images.removeObject(forKey: idValue as NSString)
                
                collectionView.reloadData()
            }
        }
    }
    
    /* 아래의 메소드는 컨트롤러의 임시 사진 데이터와 실제 데이터를 동기화 처리합니다.
     사진이 저장되거나, 삭제 됩니다.
     사용자가 Done 버튼을 누르면 반드시 호출되어야 하는 메소드입니다.
     */
    func reflectPhoto() {
        var temporaryCount = 0 // temporary 이미지에 대한 인덱스입니다.
        var permanentlyCount = 0 // 영구 저장 이미지에 대한 인덱스입니다.
        
        while temporaryCount < photos.count || permanentlyCount < memo.photos.count {
            if temporaryCount == photos.count {
                // 뒤에 있는 이미지를 모두 지웁니다.
                print("뒤를 모조리 지울 것임!")
                let deleteAmount = memo.photos.count - permanentlyCount
                print("ooooaaaaaa", deleteAmount)
                for _ in (0..<deleteAmount) {
                    let imageUrl = memo.photos[memo.photos.count - 1].url
                    RealmManager.write(realm: RealmManager.realm) {
                        RealmManager.realm.delete(memo.photos[memo.photos.count - 1])
                    }
                    // File 제거
                    imageFileManager.deleteImage(imageName: imageUrl)
                }
                break
            }
            if permanentlyCount == memo.photos.count || photos[temporaryCount].id == -1 {
                // 뒤에 있는 이미지를 모조리 추가합니다.
                print("뒤에 모조리 추가할 것임!")
                let baseId = (RealmManager.realm.objects(Photo.self).max(ofProperty: "id") as Int? ?? -1) + 1 - temporaryCount
                
                while temporaryCount < photos.count {
                    photos[temporaryCount].id = baseId + temporaryCount
                    photos[temporaryCount].url = String(baseId + temporaryCount)
                    
                    RealmManager.write(realm: RealmManager.realm) {
                        memo.photos.append(photos[temporaryCount])
                    }
                    
                    print(RealmManager.realm.objects(Photo.self))

                    resizedImageSaveQueue.async {
                        if let image = self.resizedImages[self.imageIndex[temporaryCount - self.savedPhotoCount]] {
                            self.imageFileManager.saveImage(imageName: self.photos[temporaryCount].url, image: image)
                        }
                    }

                    temporaryCount += 1
                }
                break
            }
            
            if photos[temporaryCount].id == memo.photos[permanentlyCount].id {
                print("동일한 데이터임!")
                temporaryCount += 1
                permanentlyCount += 1
            } else if photos[temporaryCount].id > memo.photos[permanentlyCount].id {
                // 이미지를 지워야 합니다.
                print("이미지를 제거해야함!")
                let imageUrl = memo.photos[permanentlyCount].url
                RealmManager.write(realm: RealmManager.realm) {
                    RealmManager.realm.delete(memo.photos.filter("id == %@", memo.photos[permanentlyCount].id))
                    //memo.photos.removeLast() // 이게 맞나? 지워줘야 하나?
                }
                imageFileManager.deleteImage(imageName: imageUrl)
            } else {
                // 항상 id가 단조증가 하므로 일어날 수 없는 동작입니다.
                print("Error occurd reflecting Photo!")
            }
        }
        savedPhotoCount = photos.count
        maxPhotoId = photos.last?.id ?? -1
    }
}

extension MemoViewContoller {
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
}

/* 아래의 익스텐션은 Add 클릭 후 ActionSheet에서 URL을 클릭했을 때
 다운로드 동작과 관련되어 있습니다.*/
extension MemoViewContoller {
    func saveDownloadedImage(downloadedImage: UIImage?) {
        //이미지가 잘 못 되었을 경우 알려주고 종료
        //이미지가 정상일 경우 저장
        if let image = downloadedImage {
            DispatchQueue.main.async { // UI 작업임으로 main에서 처리합니다.
                self.savePhotoTemporary(image: image)
            }
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
        
        //기다리는 동안 UIActivityIndicator를 출력
        DispatchQueue.main.async { // UI 작업임으로 main에서 처리합니다.
            // 이미지가 작을 경우 httpManager.getImage안의 클로저가 먼저 호출될 수 있으므로,
            // main에서 순차적으로 호출합니다.
            self.watingIndicator = self.showWatingIndicatorView(parentView: self.view)
            //url로 부터 이미지 요청
            self.httpManager.getImage(from: url, complition: { dataImage in
                DispatchQueue.main.async { // UI 작업임으로 main에서 처리합니다.
                    if let indicator = self.watingIndicator {
                        self.removeWatingIndicatorView(view: indicator)
                    }
                }
                self.saveDownloadedImage(downloadedImage: dataImage)
            })
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

extension UIViewController {
    func showWatingIndicatorView(parentView : UIView) -> UIView {
        let watingIndicatorView = UIView.init(frame: parentView.bounds)
        
        watingIndicatorView.isAccessibilityElement = true
        watingIndicatorView.accessibilityLabel = "Now processing".localized()
        
        watingIndicatorView.backgroundColor = UIColor.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
        let indicator = UIActivityIndicatorView.init(style: .whiteLarge)
        indicator.startAnimating()
        indicator.center = watingIndicatorView.center
        
        DispatchQueue.main.async {
            watingIndicatorView.addSubview(indicator)
            parentView.addSubview(watingIndicatorView)
        }
        
        return watingIndicatorView
    }
    
    func removeWatingIndicatorView(view: UIView) {
        view.removeFromSuperview()
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
            print("실패를 한다구???")
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
