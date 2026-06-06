enum ListingDetailsTab {
  overview,
  bnb,
  rent,
  finance,
  staff,
  maintenance,
}

extension ListingDetailsTabX on ListingDetailsTab {
  String labelEn() {
    switch (this) {
      case ListingDetailsTab.overview:
        return 'Overview';
      case ListingDetailsTab.bnb:
        return 'BnB';
      case ListingDetailsTab.rent:
        return 'Rent';
      case ListingDetailsTab.finance:
        return 'Finance';
      case ListingDetailsTab.staff:
        return 'Staff';
      case ListingDetailsTab.maintenance:
        return 'Maintenance';
    }
  }

  String labelSw() {
    switch (this) {
      case ListingDetailsTab.overview:
        return 'Muhtasari';
      case ListingDetailsTab.bnb:
        return 'BnB';
      case ListingDetailsTab.rent:
        return 'Kodi';
      case ListingDetailsTab.finance:
        return 'Fedha';
      case ListingDetailsTab.staff:
        return 'Wafanyakazi';
      case ListingDetailsTab.maintenance:
        return 'Matengenezo';
    }
  }
}
