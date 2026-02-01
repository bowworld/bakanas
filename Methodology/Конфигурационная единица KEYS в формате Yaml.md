---
- Input:
	Class: ITSM::ConfigItem::KEYS::Type
	Required: 1
	Translation: 1
	Type: GeneralCatalog
  Key: KeysType
  Name: Тип ключа
  Searchable: 1
- Input:
	ReferencedCIClassLinkType: DependsOn
    ReferencedCIClassName: Computer
    ReferencedCIClassReferenceAttributeKey: Name
    SearchInputType: AutoComplete
    Type: CIClassReference
  Key: Computer
  Name: Компьютер
  Searchable: 1
- Input:
	ReferencedCIClassLinkType: DependsOn
    ReferencedCIClassName: Vendor
    ReferencedCIClassReferenceAttributeKey: Name
    SearchInputType: AutoComplete
    Type: CIClassReference
  Key: Vendor
  Name: Вендор
  Searchable: 1
- Input:
	MaxLength: 150
	Size: 150
	Type: Text
	Required: 0
  Key: ToModels
  Name: К каким моделям применим
  Searchable: 0
- Input:
	Type: Date
	YearPeriodFuture: 1
	YearPeriodPast: 5
  Key: KeysActivationDay
  Name: Дата активации
  Searchable: 1
- Input:
	Type: Date
	YearPeriodFuture: 5
	YearPeriodPast: 5
  Key: KeysValidtillDate
  Name: Дата окончания активации
  Searchable: 1
- Input:
	MaxLength: 10
	Size: 10
	Type: Text
	Required: 0
  Key: Price
  Name: Цена
- Input:
	Required: 0
	Type: TextArea
  Key: Note
  Name: Процедура установки
  Searchable: 0