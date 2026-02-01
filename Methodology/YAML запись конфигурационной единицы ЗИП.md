---
- Input:
    MaxLength: 50
    Size: 50
    Type: Text
  Key: Vendor
  Name: Производитель
  Searchable: 1
- Input:
    Type: TextArea
  Key: Description
  Name: Описание
  Searchable: 1
- Input:
    Class: ITSM::ConfigItem::Spare_part::Type
    Translation: 1
    Type: GeneralCatalog
  Key: Type
  Name: Тип
  Searchable: 1
- Input:
    MaxLength: 100
    Size: 100
    Type: Text
  Key: SerialNum
  Name: Серийный номер
  Searchable: 1
- CountDefault: 0
  CountMax: 1
  CountMin: 0
  Input:
    Required: 1
    Type: Date
    YearPeriodFuture: 10
    YearPeriodPast: 20
  Key: InstallDate
  Name: Дата установки
  Searchable: 1
- CountDefault: 0
  CountMax: 1
  CountMin: 0
  Input:
    Required: 1
    Type: Date
    YearPeriodFuture: 10
    YearPeriodPast: 20
  Key: WarrantyExpirationDate
  Name: Срок истечения гарантии
  Searchable: 1
- CountDefault: 0
  CountMax: 1
  CountMin: 0
  Input:
    Required: 1
    Type: TextArea
  Key: Note
  Name: Заметка
  Searchable: 1