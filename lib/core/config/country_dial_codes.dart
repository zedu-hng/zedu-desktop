class CountryDialCode {
  const CountryDialCode(this.name, this.iso2, this.dialCode);

  final String name;
  final String iso2;
  final String dialCode;
}

const List<CountryDialCode> kCountryDialCodes = [
  CountryDialCode('Nigeria', 'NG', '+234'),
  CountryDialCode('United States', 'US', '+1'),
  CountryDialCode('Canada', 'CA', '+1'),
  CountryDialCode('United Kingdom', 'GB', '+44'),
  CountryDialCode('India', 'IN', '+91'),
  CountryDialCode('China', 'CN', '+86'),
  CountryDialCode('Japan', 'JP', '+81'),
  CountryDialCode('South Korea', 'KR', '+82'),
  CountryDialCode('Germany', 'DE', '+49'),
  CountryDialCode('France', 'FR', '+33'),
  CountryDialCode('Spain', 'ES', '+34'),
  CountryDialCode('Italy', 'IT', '+39'),
  CountryDialCode('Netherlands', 'NL', '+31'),
  CountryDialCode('Belgium', 'BE', '+32'),
  CountryDialCode('Switzerland', 'CH', '+41'),
  CountryDialCode('Austria', 'AT', '+43'),
  CountryDialCode('Sweden', 'SE', '+46'),
  CountryDialCode('Norway', 'NO', '+47'),
  CountryDialCode('Denmark', 'DK', '+45'),
  CountryDialCode('Ireland', 'IE', '+353'),
  CountryDialCode('Portugal', 'PT', '+351'),
  CountryDialCode('Poland', 'PL', '+48'),
  CountryDialCode('Ukraine', 'UA', '+380'),
  CountryDialCode('Turkey', 'TR', '+90'),
  CountryDialCode('Brazil', 'BR', '+55'),
  CountryDialCode('Mexico', 'MX', '+52'),
  CountryDialCode('Argentina', 'AR', '+54'),
  CountryDialCode('South Africa', 'ZA', '+27'),
  CountryDialCode('Kenya', 'KE', '+254'),
  CountryDialCode('Ghana', 'GH', '+233'),
  CountryDialCode('Egypt', 'EG', '+20'),
  CountryDialCode('Saudi Arabia', 'SA', '+966'),
  CountryDialCode('United Arab Emirates', 'AE', '+971'),
  CountryDialCode('Israel', 'IL', '+972'),
  CountryDialCode('Pakistan', 'PK', '+92'),
  CountryDialCode('Bangladesh', 'BD', '+880'),
  CountryDialCode('Indonesia', 'ID', '+62'),
  CountryDialCode('Malaysia', 'MY', '+60'),
  CountryDialCode('Singapore', 'SG', '+65'),
  CountryDialCode('Philippines', 'PH', '+63'),
  CountryDialCode('Thailand', 'TH', '+66'),
  CountryDialCode('Vietnam', 'VN', '+84'),
  CountryDialCode('Australia', 'AU', '+61'),
  CountryDialCode('New Zealand', 'NZ', '+64'),
];
