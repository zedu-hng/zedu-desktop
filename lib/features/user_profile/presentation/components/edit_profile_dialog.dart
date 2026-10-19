import 'package:zedu/core/core.dart';
import 'package:zedu/features/features.dart';

/// A list of common timezone labels for the timezone dropdown.
const List<String> _kTimezones = [
  '(UTC-12:00) International Date Line West',
  '(UTC-11:00) Midway Island, Samoa',
  '(UTC-10:00) Hawaii',
  '(UTC-09:00) Alaska',
  '(UTC-08:00) Pacific Time (US & Canada)',
  '(UTC-07:00) Mountain Time (US & Canada)',
  '(UTC-06:00) Central Time (US & Canada)',
  '(UTC-05:00) Eastern Time (US & Canada)',
  '(UTC-04:00) Atlantic Time (Canada)',
  '(UTC-03:00) Buenos Aires, Georgetown',
  '(UTC-02:00) Mid-Atlantic',
  '(UTC-01:00) Azores, Cape Verde Islands',
  '(UTC+00:00) London, Dublin, Lisbon',
  '(UTC+01:00) West Central Africa',
  '(UTC+02:00) Cairo, Helsinki, Bucharest',
  '(UTC+03:00) Moscow, Nairobi, Baghdad',
  '(UTC+04:00) Abu Dhabi, Muscat',
  '(UTC+05:00) Islamabad, Karachi',
  '(UTC+05:30) Chennai, Kolkata, Mumbai',
  '(UTC+06:00) Almaty, Dhaka',
  '(UTC+07:00) Bangkok, Hanoi, Jakarta',
  '(UTC+08:00) Beijing, Singapore, Perth',
  '(UTC+09:00) Tokyo, Seoul, Osaka',
  '(UTC+10:00) Sydney, Guam, Vladivostok',
  '(UTC+11:00) Solomon Islands, New Caledonia',
  '(UTC+12:00) Auckland, Wellington, Fiji',
];

Future<void> showEditProfileDialog(
  BuildContext context,
  ProfileAccount account,
  ValueChanged<ProfileAccount> onSave,
) async {
  await showDialog<void>(
    context: context,
    builder: (context) => _EditProfileDialog(account: account, onSave: onSave),
  );
}

class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog({required this.account, required this.onSave});

  final ProfileAccount account;
  final ValueChanged<ProfileAccount> onSave;

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late final TextEditingController nameCtrl;
  late final TextEditingController displayNameCtrl;
  late final TextEditingController usernameCtrl;
  late final TextEditingController emailCtrl;
  late final TextEditingController phoneCtrl;
  late final TextEditingController titleCtrl;
  late final TextEditingController pronunciationCtrl;

  final formKey = GlobalKey<FormState>();

  late String selectedTimezone;
  late String selectedCountry;
  late CountryDialCode phoneCountry;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.account.name);
    displayNameCtrl = TextEditingController(text: widget.account.displayName);
    usernameCtrl = TextEditingController(text: widget.account.username);
    emailCtrl = TextEditingController(text: widget.account.email);
    phoneCtrl = TextEditingController(text: widget.account.phoneNumber);
    titleCtrl = TextEditingController(text: widget.account.title);
    pronunciationCtrl = TextEditingController(
      text: widget.account.namePronunciation,
    );

    selectedTimezone = widget.account.timezone.isNotEmpty
        ? widget.account.timezone
        : _kTimezones.first;
    selectedCountry = widget.account.country;
    phoneCountry = kCountryDialCodes.firstWhere(
      (c) => widget.account.phoneNumber.trimLeft().startsWith(c.dialCode),
      orElse: () => kCountryDialCodes.first,
    );
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    displayNameCtrl.dispose();
    usernameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    titleCtrl.dispose();
    pronunciationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 640,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Edit your profile',
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: colors.textHint),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Divider(height: 0, color: colors.divider),

            // Scrollable form body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Form(
                  key: formKey,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left column — form fields
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppTextField(
                              label: 'Full Name',
                              controller: nameCtrl,
                              hint: 'Enter your full name',
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Name is required'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              label: 'Display Name',
                              controller: displayNameCtrl,
                              hint: 'Enter display name',
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'This could be your first name, or a nickname — however you\'d like people to refer to you.',
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: colors.textHint,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              label: 'Username',
                              controller: usernameCtrl,
                              hint: 'Enter username',
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              label: 'Email',
                              controller: emailCtrl,
                              hint: 'Enter your email',
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Email is required';
                                }
                                if (!v.contains('@')) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              label: 'Phone Number',
                              controller: phoneCtrl,
                              hint: '801 234 5678',
                              keyboardType: TextInputType.phone,
                              prefix: CountryDialCodeSelector(
                                selected: phoneCountry,
                                onSelected: (country) {
                                  setState(() => phoneCountry = country);
                                  final current = phoneCtrl.text.trim();
                                  if (current.isEmpty ||
                                      RegExp(r'^\+\d+$').hasMatch(current)) {
                                    phoneCtrl.text = '${country.dialCode} ';
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              label: 'Title',
                              controller: titleCtrl,
                              hint: 'e.g. Product Manager',
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              label: 'Name Pronunciation',
                              controller: pronunciationCtrl,
                              hint: "e.g. Zoe (pronounced 'zo-ee')",
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'This could be a phonetic pronunciation, or an example of something your name sounds like.',
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: colors.textHint,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Timezone dropdown
                            ProfileFieldLabel('Timezone'),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              initialValue:
                                  _kTimezones.contains(selectedTimezone)
                                  ? selectedTimezone
                                  : _kTimezones.first,
                              isExpanded: true,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(color: colors.divider),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(color: colors.divider),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                              ),
                              items: _kTimezones
                                  .map(
                                    (tz) => DropdownMenuItem(
                                      value: tz,
                                      child: Text(
                                        tz,
                                        style: context.textTheme.bodySmall,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => setState(
                                () => selectedTimezone = v ?? selectedTimezone,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Country dropdown (searchable)
                            ProfileFieldLabel('Country'),
                            const SizedBox(height: 6),
                            Autocomplete<String>(
                              initialValue: TextEditingValue(
                                text: selectedCountry,
                              ),
                              optionsBuilder: (textEditingValue) {
                                if (textEditingValue.text.isEmpty) {
                                  return kCountries;
                                }
                                return kCountries.where(
                                  (c) => c.toLowerCase().contains(
                                    textEditingValue.text.toLowerCase(),
                                  ),
                                );
                              },
                              onSelected: (value) {
                                setState(() => selectedCountry = value);
                              },
                              fieldViewBuilder:
                                  (
                                    context,
                                    controller,
                                    focusNode,
                                    onFieldSubmitted,
                                  ) {
                                    return TextFormField(
                                      controller: controller,
                                      focusNode: focusNode,
                                      decoration: InputDecoration(
                                        hintText: 'Search or select a country',
                                        hintStyle: context.textTheme.bodySmall
                                            ?.copyWith(color: colors.textHint),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          borderSide: BorderSide(
                                            color: colors.divider,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          borderSide: BorderSide(
                                            color: colors.divider,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 14,
                                            ),
                                        suffixIcon: Icon(
                                          Icons.keyboard_arrow_down,
                                          color: colors.textHint,
                                        ),
                                      ),
                                      style: context.textTheme.bodySmall,
                                      onFieldSubmitted: (_) =>
                                          onFieldSubmitted(),
                                    );
                                  },
                              optionsViewBuilder:
                                  (context, onSelected, options) {
                                    return Align(
                                      alignment: Alignment.topLeft,
                                      child: Material(
                                        elevation: 4,
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          width: 360,
                                          constraints: const BoxConstraints(
                                            maxHeight: 240,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colors.background,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: colors.divider,
                                            ),
                                          ),
                                          child: ListView.builder(
                                            padding: EdgeInsets.zero,
                                            shrinkWrap: true,
                                            itemCount: options.length,
                                            itemBuilder: (context, index) {
                                              final option = options.elementAt(
                                                index,
                                              );
                                              return InkWell(
                                                onTap: () => onSelected(option),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 10,
                                                      ),
                                                  child: Text(
                                                    option,
                                                    style: context
                                                        .textTheme
                                                        .bodySmall,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),

                      // Right column — profile photo
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Profile Photo',
                              style: context.textTheme.labelSmall?.copyWith(
                                color: colors.textHint,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: Container(
                                width: 160,
                                height: 160,
                                decoration: BoxDecoration(
                                  color: colors.accent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.person,
                                  size: 80,
                                  color: colors.accent,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: TextButton.icon(
                                onPressed: () {
                                  // Upload photo placeholder
                                },
                                icon: Icon(
                                  Icons.upload_outlined,
                                  size: 16,
                                  color: colors.primary,
                                ),
                                label: Text(
                                  'Upload photo',
                                  style: context.textTheme.bodySmall?.copyWith(
                                    color: colors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  // Remove photo placeholder
                                },
                                child: Text(
                                  'Remove photo',
                                  style: context.textTheme.bodySmall?.copyWith(
                                    color: colors.error,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            Divider(height: 0, color: colors.divider),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: colors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  AppButton(
                    label: 'Save Changes',
                    expand: false,
                    height: 40,
                    onPressed: () {
                      if (formKey.currentState?.validate() ?? false) {
                        widget.onSave(
                          widget.account.copyWith(
                            name: nameCtrl.text.trim(),
                            displayName: displayNameCtrl.text.trim(),
                            username: usernameCtrl.text.trim(),
                            email: emailCtrl.text.trim(),
                            phoneNumber: phoneCtrl.text.trim(),
                            title: titleCtrl.text.trim(),
                            namePronunciation: pronunciationCtrl.text.trim(),
                            timezone: selectedTimezone,
                            country: selectedCountry,
                          ),
                        );
                        Navigator.pop(context);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CountryDialCodeSelector extends StatelessWidget {
  const CountryDialCodeSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final CountryDialCode selected;
  final ValueChanged<CountryDialCode> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: () async {
        final country = await showDialog<CountryDialCode>(
          context: context,
          builder: (context) => const _CountryDialCodePicker(),
        );
        if (country != null) {
          onSelected(country);
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${selected.iso2} ${selected.dialCode}',
            style: context.textTheme.bodyLarge?.copyWith(
              color: colors.textPrimary,
            ),
          ),
          Icon(Icons.arrow_drop_down, size: 18, color: colors.textHint),
        ],
      ),
    );
  }
}

class _CountryDialCodePicker extends StatefulWidget {
  const _CountryDialCodePicker();

  @override
  State<_CountryDialCodePicker> createState() => _CountryDialCodePickerState();
}

class _CountryDialCodePickerState extends State<_CountryDialCodePicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final query = _query.toLowerCase();
    final results = query.isEmpty
        ? kCountryDialCodes
        : kCountryDialCodes
              .where(
                (c) =>
                    c.name.toLowerCase().contains(query) ||
                    c.iso2.toLowerCase().contains(query) ||
                    c.dialCode.contains(_query),
              )
              .toList();
    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      content: SizedBox(
        width: 300,
        height: 360,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Search or select a country',
                prefixIcon: Icon(Icons.search, color: colors.textHint),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: colors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: colors.divider),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final country = results[index];
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      country.name,
                      style: context.textTheme.bodyMedium,
                    ),
                    trailing: Text(
                      country.dialCode,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: colors.textHint,
                      ),
                    ),
                    onTap: () => Navigator.pop(context, country),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
