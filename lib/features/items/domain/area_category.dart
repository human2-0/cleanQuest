enum AreaCategory {
  home,
  car,
  other,
}

extension AreaCategoryLabel on AreaCategory {
  String get label {
    switch (this) {
      case AreaCategory.home:
        return 'Home';
      case AreaCategory.car:
        return 'Car';
      case AreaCategory.other:
        return 'Other';
    }
  }
}
