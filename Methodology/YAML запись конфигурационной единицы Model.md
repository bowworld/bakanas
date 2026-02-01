---
- Input:
    ReferencedCIClassLinkDirection: Reverse
    ReferencedCIClassLinkType: RelevantTo
    ReferencedCIClassName: Vendor
    ReferencedCIClassReferenceAttributeKey: Name
    SearchInputType: AutoComplete
    Type: CIClassReference
  Key: Vendor
  Name: Производитель
  Searchable: 1
- Input:
    ReferencedCIClassLinkDirection: Reverse
    ReferencedCIClassLinkType: RelevantTo
    ReferencedCIClassName: EquipmentType
    ReferencedCIClassReferenceAttributeKey: Name
    SearchInputType: AutoComplete
    Type: CIClassReference
  Key: EquipmentType
  Name: Тип оборудования
  Searchable: 1
- Input:
    Type: TextArea
  Key: Description
  Name: Описание
  Searchable: 1
- CountMax: 10
  Input:
    Required: 0
    Type: Integer
    ValueMax: 10
    ValueMin: 1
  Key: LifeYear
  Name: Год цикла
  Sub:
  - CountMax: 100
    Input:
      MaxLength: 40
      Size: 40
      Type: Text
    Key: PartNumber
    Name: Партномер
    Sub:
    - Input:
        MaxLength: 100
        Size: 100
        Type: Text
      Key: ZIPDescription
      Name: Описание ЗИП
    - Input:
        Type: Integer
        ValueMax: 100
        ValueMin: 1
      Key: RequiredQnt
      Name: Необходимое количество