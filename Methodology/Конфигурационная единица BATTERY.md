---
- Key: UPS
  Name: ИБП
  Searchable: 1
  Input:
    Type: CIClassReference
    ReferencedCIClassLinkDirection: Reverse
    ReferencedCIClassLinkType: RelevantTo
    ReferencedCIClassName: UPS
    ReferencedCIClassReferenceAttributeKey: Name
    SearchInputType: AutoComplete
- Key: BatteryProducer
  Name: Производитель батарей
  Searchable: 1
  Input:
    Type: Text
    Required: 1
    Size: 50
    MaxLength: 100
- Key: BatteryModel
  Name: Модель батарей
  Searchable: 1
  Input:
    Type: Text
    Required: 1
    Size: 50
    MaxLength: 100
- Key: BatteryVoltage
  Name: Напряжение батарей (Вольт)
  Searchable: 1
  Input:
    Type: Text
    Required: 1
    Size: 3
    MaxLength: 3
    RegEx: ^\d+$
    RegExErrorMessage: Нужно вводить только цифры
    ValueMin: 1
    ValueMax: 999
    ValueDefault: 12
- Key: BatteryCapacity
  Name: Емкость батарей (Ампер/час)
  Searchable: 1
  Input:
    Type: Text
    Required: 1
    Size: 3
    MaxLength: 3
    RegEx: ^\d+$
    RegExErrorMessage: Нужно вводить только цифры
    ValueMin: 1
    ValueMax: 999
    ValueDefault: 9
- Key: MeasuringRate
  Name: Коэффициент измерения
  Searchable: 0
  Input:
    Type: Text
    Size: 4
- Key: ChargeCurrent
  Name: Ток заряда батарей (A)
  Searchable: 0
  Input:
    Type: Text
    Required: 0
    Size: 4
    MaxLength: 4
    RegEx: ^\d+$
    RegExErrorMessage: Нужно вводить только цифры
    ValueMin: 1
    ValueMax: 9999
    ValueDefault: 1
- Key: DischargeCurrent
  Name: Ток разряда батарей (A)
  Searchable: 0
  Input:
    Type: Text
    Required: 0
    Size: 4
    MaxLength: 4
    RegEx: ^\d+$
    RegExErrorMessage: Нужно вводить только цифры
    ValueMin: 1
    ValueMax: 9999
    ValueDefault: 1
- Key: ChargeVoltage
  Name: Напряжение заряда батарей (V)
  Searchable: 0
  Input:
    Type: Text
    Required: 0
    Size: 4
    MaxLength: 4
    RegEx: ^\d+$
    RegExErrorMessage: Нужно вводить только цифры
    ValueMin: 1
    ValueMax: 9999
    ValueDefault: 460
- Key: AkbLocation
  Name: Расположение АКБ
  Input:
    Type: Dummy
  Sub:
  - Key: BatteryLineNum
    Name: Номер батарейной линейки
    Searchable: 0
    Input:
      Type: Text
      Required: 1
      Size: 2
      MaxLength: 2
      RegEx: ^\d+$
      RegExErrorMessage: Нужно вводить только цифры
      ValueMin: 0
      ValueMax: 99
      ValueDefault: 0
    CountMin: 0
    CountMax: 99
    CountDefault: 0
    Sub:
    - Key: BatteryModuleNum
      Name: Номер батарейной полки или модуля
      Searchable: 0
      Input:
        Type: Text
        Required: 1
        Size: 2
        MaxLength: 2
        RegEx: ^\d+$
        RegExErrorMessage: Нужно вводить только цифры
        ValueMin: 0
        ValueMax: 99
        ValueDefault: 0
      CountMin: 1
      CountMax: 99
      CountDefault: 1  
      Sub:
      - Key: BatteryNum
        Name: Номер АКБ
        Input:
          Type: Text
          Required: 1
          Size: 2
          ValueMin: 0
          ValueMax: 99
          ValueDefault: 0
        CountMin: 1
        CountMax: 99
        CountDefault: 1
        Sub:
        - Key: AkbVoltage
          Name: Напряжение АКБ (Вольт)
          Input:
            Type: Text
            Size: 3
            Required: 1
            ValueMin: 0
            ValueMax: 999
            ValueDefault: 12
        - Key: AkbCapacity
          Name: Емкость АКБ (Ампер/час)
          Input:
            Type: Text
            Size: 3
            Required: 1
            ValueMin: 0
            ValueMax: 999
            ValueDefault: 7.2
        - Key: AkbDecision
          Name: Заключение по АКБ
          Input:
            Type: GeneralCatalog
            Class: ITSM::ConfigItem::UPS::AkbDecision
            Required: 1