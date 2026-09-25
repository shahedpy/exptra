class AccountTypeClass {
  static const liquid = 'liquid';
  static const investment = 'investment';
  static const other = 'other';
  static const values = [liquid, investment, other];

  static String label(String value) => switch (value) {
    liquid => 'Available / Liquid',
    investment => 'Investment',
    _ => 'Other',
  };
}

class DefaultAccountType {
  final String id;
  final String name;
  final String classification;
  final bool requiresInstitution;
  const DefaultAccountType(
    this.id,
    this.name,
    this.classification,
    this.requiresInstitution,
  );
}

const defaultAccountTypes = <DefaultAccountType>[
  DefaultAccountType(
    'system-savings',
    'Savings',
    AccountTypeClass.liquid,
    true,
  ),
  DefaultAccountType(
    'system-current',
    'Current',
    AccountTypeClass.liquid,
    true,
  ),
  DefaultAccountType('system-cash', 'Cash', AccountTypeClass.liquid, false),
  DefaultAccountType(
    'system-mobile-wallet',
    'Mobile Wallet',
    AccountTypeClass.liquid,
    false,
  ),
  DefaultAccountType('system-fdr', 'FDR', AccountTypeClass.investment, true),
  DefaultAccountType('system-dps', 'DPS', AccountTypeClass.investment, true),
  DefaultAccountType(
    'system-investment',
    'Investment',
    AccountTypeClass.investment,
    false,
  ),
  DefaultAccountType('system-other', 'Other', AccountTypeClass.other, false),
];
