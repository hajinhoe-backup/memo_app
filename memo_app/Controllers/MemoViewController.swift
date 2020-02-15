//
//  MemoDetailViewController.swift
//  memo_app
//
//  Created by jinho on 2020/02/10.
//  Copyright © 2020 jinho. All rights reserved.
//

// 걍 뷰 하나로 iseddit으로 해서 숨기는 게 나을 듯;;

// top으로 스크롤 되어야함. 좌표가
import UIKit

class MemoViewContoller: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    /* 아래의 변수는 컨트롤러를 재활용할 때, imagePicker등의 내부에서 작동하게 되는 View들에 의해
     viewWillApear의 동작을 또 다시 하지 않게 하기 위한 변수입니다. */
    var needInitialize = true
    
    var imagePicker = UIImagePickerController()
    
    var memo = Memo()
    
    /* photos 리스트의 값과 memo의 값이 다를 수 있습니다.
     실제로 memo 안의 photos는 메모가 Done 버튼을 통해 저장될 때만, 업데이트 되며,
     이 photos는 뷰의 상태 표시와 업데이트를 위한 것입니다.
    */
    var photos: [Photo] = []
    
    /* images의 값이 실제로 영구 저장소에 올라가있지 않을 수 있습니다.
     Done을 통해 Save 될 때만, 저장되지 않은 이미지가 올라갑니다. */
    var images: [UIImage] = []
    
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
    

    func setupTextView(_ cellTitleView: UIView) {
        cellTitleView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            cellTitleView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 0),
            cellTitleView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: 0),
            cellTitleView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 0),
            cellTitleView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 0),
            //cellTitleView.heightAnchor.constraint(equalToConstant: 150.0)
        ])
    }
    
    override func viewDidLoad() { // 근데 ? 붙여야 하던가?
        print("조사포인트1")
        super.viewDidLoad()
        
        
        collectionView.backgroundColor = .white
        layout.headerReferenceSize = CGSize(width: collectionView.frame.width, height: 50)
        layout.sectionInset = UIEdgeInsets(top: 2.5, left: 10, bottom: 2.5, right: 10)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 5
        collectionView?.collectionViewLayout = layout
        collectionView?.dataSource = self
        collectionView?.delegate = self
        imagePicker.delegate = self
        
        collectionView.collectionViewLayout.invalidateLayout()
        
        collectionView.register(MemoPhotoItemCellView.self, forCellWithReuseIdentifier: "cellId")
        collectionView.register(MemoPhotoItemCellWithDeleteButtonView.self, forCellWithReuseIdentifier: "cellIdw")
        collectionView.register(MemoHeaderCellView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "memoHeaderCellView")
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "< Back", style: .plain, target: self, action: #selector(dismissView))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("조사포인트2")
        super.viewWillAppear(animated)
        
        if needInitialize {
            titleText = memo.title
            contentText = memo.content

            /* 뷰를 로드하기 전에 첨부 사진 데이터를 초기화 후, 로드합니다. */
            
            photos.removeAll(keepingCapacity: false)
            images.removeAll(keepingCapacity: false)
            collectionView.reloadData() // ㅡㅡ??????? 왜 이거 추가해야함? 논리적 설명좀... ios13에서는 없어도 되는데 10에서는 추가해야하네? 명시적으로 한번 삭제해주라는 뜻임?
            
            for photo in memo.photos {
                photos.append(photo)
                images.append(ImageFileManager.getSavedImage(named: photo.url) ?? UIImage())
            }
            
            /* 뷰의 상태에 맞게 뷰를 갱신합니다. */
            /* 실제로 뷰 호출시에는 첫 글 쓰기, 또는 보기 모드이므로 두 가지 경우에만 해당합니다. */
            if isFirstWrite && enableWriteLayout {
                enableFisrtWriting()
            } else if (!isFirstWrite && !enableWriteLayout) {
                enableViewMode()
            }
            
            //collectionView.endEditing(true)
            //collectionView.reloadSections([0]) //헤더를 리로드합니다.
            ///collectionView.reloadInputViews()
            //collectionView.collectionViewLayout.invalidateLayout()
            
            needInitialize = false
            
        }
    }
    
    @objc func dismissView() {
        navigationController?.popViewController(animated: true)
        //self.dismiss(animated: true, completion: nil)
    }
    
    func changeRightNavigationItemToEdit() {
        navigationItem.rightBarButtonItems = [UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(layoutToEditMode))]
    }
    
    func changeRightNavigationItemToDone() {
        if isFirstWrite {
            navigationItem.rightBarButtonItems = [UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(editModeIsDone))]
        } else {
            navigationItem.rightBarButtonItems = [UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(editModeIsDone)), UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteMemo))]
        }
    }
    
    /* delete 버튼을 클릭 했을 때, 메모의 모든 사진을 순회하여 삭제하고,
     메모 자체를 삭제한 후, 리스트 뷰로 되돌아 갑니다. */
    @objc func deleteMemo() {
        for photo in memo.photos {
            ImageFileManager.deleteImage(imageName: photo.url)
        }
        
        RealmManager.write(realm: RealmManager.realm) {
            RealmManager.realm.delete(memo.photos)
            RealmManager.realm.delete(memo)
        }
        
        dismissView()
    }
    
    func renderMemoPhotoItemCell() {
        collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems) //보이는 셀만 버튼 추가해서 새로 그림
        layout.invalidateLayout()
        //collectionView.setNeedsLayout()
        //collectionView.layoutSubviews()
        //layout.invalidateLayout()
        //self.collectionView.layoutSubviews()
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
    func enableFisrtWriting() { //메서드 이름을 changeTo로 바꿀 것
        isFirstWrite = true
        layoutToEditMode()
    }
    
    func enableEditMode() { // 아직 사용 예정이 없음
        isFirstWrite = false
        layoutToEditMode()
    }
    
    func enableViewMode() {
        isFirstWrite = false
        layoutToViewMode()
    }
    
    /* 데이터 베이스에 새로운 메모를 추가하고, 처음 자성 모드를 끝냅니다. */
    func saveMemo() {
        memo.title = titleText
        memo.content = contentText
        memo.id = (RealmManager.realm.objects(Memo.self).max(ofProperty: "id") as Int? ?? -1) + 1
        RealmManager.write(realm: RealmManager.realm) {
            RealmManager.realm.add(memo)
        }
        isFirstWrite = false
    }
    
    /* 데이터 베이스의 메모를 수정합니다. */
    func editMemo() {
        RealmManager.write(realm: RealmManager.realm) {
            memo.title = titleText
            memo.content = contentText
        }
        
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
        navigationItem.title = "Writing"
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
        navigationItem.title = "Memo"
        changeRightNavigationItemToEdit()
    }
    
    @objc func editModeIsDone() {
        collectionView.endEditing(true)
        
        if isFirstWrite { // 처음 작성
            saveMemo()
        } else { // 있던 글 편집
            editMemo()
        }
        
        reflectPhoto()
        
        layoutToViewMode()
        renderMemoPhotoItemCell()
        changeRightNavigationItemToEdit()
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {

    switch kind {

    case UICollectionView.elementKindSectionHeader:
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "memoHeaderCellView", for: indexPath) as! MemoHeaderCellView

        
        //collectionView.collectionViewLayout.invalidateLayout()
    
        
        headerView.textView.text = contentText
        headerView.titleView.text = titleText
        
        headerView.textView.delegate = self
        headerView.titleView.delegate = self
        
  
        headerView.setNeedsLayout() //필요
        headerView.layoutIfNeeded()
        
        headerView.layoutSubviews()
        headerView.setNeedsLayout()
        
        let calculatedHeight = headerView.verticalStackView.subviews//[0..<headerView.verticalStackView.subviews.count - 1]
            .map({
                $0.sizeThatFits(CGSize(width: $0.frame.width, height: CGFloat.infinity)).height
            })
            .reduce(0, {$0 + $1}) //+ 50// + 40//맵 리듀스 개쩖! ㅡㅡ 도저히 모르겠다 왜 ??? 40 은 따로해야함?
        
        print("What?",
            headerView.verticalStackView.subviews
            .map({
                max($0.sizeThatFits(CGSize(width: $0.frame.width, height: CGFloat.infinity)).height,
                    $0.frame.height)
            }))
        print("d아아아아")
        print(headerView.verticalStackView.heightAnchor)
        print(headerView.verticalStackView.frame.height)
        
        print("What?",
            headerView.verticalStackView.sizeThatFits(CGSize(width: headerView.verticalStackView.frame.width, height: CGFloat.infinity)).height
        )
        
        
        
        // 뭔가 textview는 infinity로 함ㄴ 뷰가 보이기 전에도 사이즈가 sizeTahtFits로 반영이 되는데, stackview는 그게 안되는 거 같음. 수동으로 넣음
        
        layout.headerReferenceSize = CGSize(width: view.frame.width, height: calculatedHeight)
        
        print("왜 두번?")
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
        headerView.layoutSubviews()
        headerView.setNeedsLayout()
        
        return headerView

    default:

        assert(false, "Unexpected element kind")
    }
    }
    
    @objc func imageAddButtonActionSheet() {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let cameraAction = UIAlertAction(title: "Camera", style: .default)
        let cameraRollAction = UIAlertAction(title: "CameraRoll", style: .default, handler: {
            _ in
            self.openCameraRoll()
        })
        let imageFromUrlAction = UIAlertAction(title: "URL", style: .default)
        let cancelAcion = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        actionSheet.addAction(cameraAction)
        actionSheet.addAction(cameraRollAction)
        actionSheet.addAction(imageFromUrlAction)
        actionSheet.addAction(cancelAcion)
        
        present(actionSheet, animated: true, completion: nil)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
    }

    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if !enableWriteLayout {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellId", for: indexPath) as! MemoPhotoItemCellView
            cell.imageView.image = images[indexPath.item]
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellIdw", for: indexPath) as! MemoPhotoItemCellWithDeleteButtonView
            cell.imageView.image = images[indexPath.item]
            cell.deleteButton.indexPath = indexPath
            cell.deleteButton.addTarget(self, action: #selector(imageDelete(senderButton:)), for: .touchUpInside)
            return cell
        }
        //cell.isEditMode = false
        
    }
    
    //위치 꼭 옮기기
    @objc func imageDelete(senderButton: UIButton) {
        if let button = senderButton as? ButtonWithIndexPath {
            if let index = button.indexPath?.item {
                photos.remove(at: index)
                images.remove(at: index)
                collectionView.reloadData()
            }
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if enableWriteLayout {
            return CGSize(width: self.view.frame.width / 2 - 20, height: 200)
        } else {
            return CGSize(width: self.view.frame.width / 2 - 20, height: 150)
        }
    }
}

extension MemoViewContoller: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        /* 컬렉션 뷰를 딜레게이트로 지정한 텍스트 뷰들에 대한 딜리게이트 함수를 시행합니다.
         컬렉션 뷰 헤더의 텍스트 뷰가 변화하면 높이를 계산하여, 레이아웃을 능동적으로 변화시킵니다.*/
        
        let calculatedHeight = textView.superview?.subviews
            .map({
                $0.sizeThatFits(CGSize(width: $0.frame.width, height: CGFloat.infinity)).height
            })
            .reduce(0, {$0 + $1}) //맵 리듀스 개쩖!
        
        print(
            textView.superview?.subviews
        .map({
            $0.sizeThatFits(CGSize(width: $0.frame.width, height: CGFloat.infinity)).height
        }))
        
        
        layout.headerReferenceSize = CGSize(width: view.frame.width, height: calculatedHeight ?? 50)
        
        layout.invalidateLayout()
        self.collectionView.layoutSubviews()
    }
    
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
                    ImageFileManager.deleteImage(imageName: imageUrl)
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
                    ImageFileManager.saveImage(imageName: photos[temporaryCount].url, image: images[temporaryCount])
                    
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
                ImageFileManager.deleteImage(imageName: imageUrl)
            } else {
                // 항상 id가 단조증가 하므로 일어날 수 없는 동작입니다.
                print("Error occurd reflecting Photo!")
            }
        }
    }
    
    /* 아래의 메소드는 컨트롤러에 메모리를 임시로 합니다.
     사용자가 Done 버튼을 누르지 않으면 내용은 영구적으로는 반영되지 않습니다.*/
    func savePhotoTemporary(image: UIImage) {
        photos.append(Photo())
        images.append(image)
        collectionView.reloadData()
    }
}


extension MemoViewContoller: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    // ios13+ : View가 모달로 보여서 viewwillapear 호출을 안 함.
    // ios13- : View가 fullscreen이기 때문에 viewwillapear를 호출함.
    func openCameraRoll() {
        imagePicker.sourceType = .photoLibrary
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
