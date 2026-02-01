---
- Key: UPS
  Name: ИБП
  Searchable: 0
  Input:
    ReferencedCIClassLinkDirection: Reverse
    ReferencedCIClassLinkType: RelevantTo
    ReferencedCIClassName: UPS
    ReferencedCIClassReferenceAttributeKey: Name
    SearchInputType: AutoComplete
    Type: CIClassReference
- Key: CapacitorType
  Name: Тип конденсатора
  Searchable: 1
  Input:
    Type: GeneralCatalog
    Class: ITSM::ConfigItem::CAPACITOR::Type
    Required: 1
- Key: CapacitorVoltage
  Name: Напряжение конденсатора (V)
  Searchable: 1
  Input:
    Type: Text
    Required: 1
    Size: 3
- Key: CapacitorUncertainty
  Name: Погрешность конденсатора +/- (%)
  Searchable: 0
  Input:
    Type: Text
    Required: 1
    MaxLength: 2
    RegEx: ^\d+$
    RegExErrorMessage: Нужно вводить только цифры
    ValueMin: 1
    ValueMax: 99
- Key: CapacitorNum
  Name: Номер конденсатора
  Searchable: 0
  Input:
    Type: Text
    Required: 1
    MaxLength: 3
    RegEx: ^\d+$
    RegExErrorMessage: Нужно вводить только цифры
    ValueMin: 1
    ValueMax: 999
  CountMin: 1
  CountMax: 999
  CountDefault: 1
  Sub:
  - Key: CapacitorCapacity
    Name: Емкость конденсатора (µF)
    Searchable: 1
    Input:
      Type: Text
      Required: 1
      Size: 3
  - Key: CapacitorDecision
    Name: Заключение инженера по конденсатору
    Searchable: 1
    Input:
      Type: GeneralCatalog
      Class: ITSM::ConfigItem::CAPACITOR::Decision
      Required: 1