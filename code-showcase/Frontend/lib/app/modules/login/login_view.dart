import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/user_preference_service.dart';
import 'login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final UserPreferenceService prefs = UserPreferenceService.instance;

    // Load saved language code
    String savedLang = prefs.getAppLanguage();
    List<String> savedUsernames = prefs.getUserName();
    Locale selectedLocale = _localeFromCode(savedLang);

    // --- NEUMORPHIC COLOR PALETTE ---
    //const Color neuBackground = Color(0xFFE0E5EC);
    const Color neuBackground = Color(0xFFE0E5EC);
    const Color neuShadowDark = Color(0xFFA3B1C6);
    const Color neuShadowLight = Colors.white;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: neuBackground,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 650),
            // Outer Neumorphic Card
            child: Container(
              decoration: BoxDecoration(
                color: neuBackground,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(
                    color: neuShadowDark,
                    offset: Offset(10, 10),
                    blurRadius: 20,
                  ),
                  BoxShadow(
                    color: neuShadowLight,
                    offset: Offset(-10, -10),
                    blurRadius: 20,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Row(
                children: [
                  // ==========================================
                  // LEFT PANEL: BRANDING (Red Gradient)
                  // ==========================================
                  Expanded(
                    flex: 4,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF9B0D0D), Color(0xFFDF3030)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Language Dropdown
                          Padding(
                            padding: const EdgeInsets.only(left: 20, top: 20),
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: DropdownButton<Locale>(
                                  value: selectedLocale,
                                  underline: const SizedBox(),
                                  dropdownColor: const Color(0xFF9B0D0D),
                                  icon: const Icon(
                                    Icons.language,
                                    color: Colors.white,
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: Locale('en', 'US'),
                                      child: Text(
                                        "English",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: Locale('zh', 'CN'),
                                      child: Text(
                                        "中文",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: Locale('ms', 'MY'),
                                      child: Text(
                                        "Bahasa",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                  onChanged: (locale) async {
                                    if (locale != null) {
                                      selectedLocale = locale;
                                      Get.updateLocale(locale);
                                      await prefs.setAppLanguage(
                                        locale.languageCode,
                                      );
                                      (context as Element).markNeedsBuild();
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),

                          // --- SQUARE LOGO BADGE ---
                          Container(
                            width: 140,
                            height: 140,
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              // 1. Use BorderRadius instead of BoxShape.circle
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            // 2. Use ClipRRect instead of ClipOval
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Image.asset(
                                'assets/images/app_logo.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),

                          const SizedBox(height: 25),

                          // App Title
                          const Text(
                            "POS NOW PRO",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.5,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  offset: Offset(0, 4),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),

                          const Text(
                            "Version 1.0.0",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w300,
                            ),
                          ),

                          const Spacer(flex: 2),
                        ],
                      ),
                    ),
                  ),

                  // ==========================================
                  // RIGHT PANEL: LOGIN FORM
                  // ==========================================
                  Expanded(
                    flex: 6,
                    child: Container(
                      color: neuBackground,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 50,
                        vertical: 10,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Text(
                          //   "Welcome Back".tr,
                          //   style: TextStyle(
                          //     fontSize: 28,
                          //     fontWeight: FontWeight.bold,
                          //     color: Colors.grey.shade800,
                          //   ),
                          // ),
                          // const SizedBox(height: 10),

                          // --- USERNAME FIELD ---
                          Container(
                            decoration: BoxDecoration(
                              color: neuBackground,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(
                                  color: neuShadowDark,
                                  offset: Offset(5, 5),
                                  blurRadius: 10,
                                ),
                                BoxShadow(
                                  color: neuShadowLight,
                                  offset: Offset(-5, -5),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Autocomplete<String>(
                              optionsBuilder:
                                  (TextEditingValue textEditingValue) {
                                    if (textEditingValue.text.isEmpty) {
                                      return savedUsernames;
                                    }
                                    return savedUsernames.where(
                                      (String option) =>
                                          option.toLowerCase().contains(
                                            textEditingValue.text.toLowerCase(),
                                          ),
                                    );
                                  },
                              onSelected: (String selection) {
                                controller.usernameController.text = selection;
                              },
                              fieldViewBuilder:
                                  (
                                    context,
                                    fieldController,
                                    fieldFocusNode,
                                    onFieldSubmitted,
                                  ) {
                                    controller.usernameController =
                                        fieldController;
                                    return TextFormField(
                                      controller: fieldController,
                                      focusNode: fieldFocusNode,
                                      style: TextStyle(
                                        color: Colors.grey.shade800,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: "Username".tr,
                                        labelStyle: TextStyle(
                                          color: Colors.grey.shade500,
                                        ),
                                        prefixIcon: const Icon(
                                          Icons.person_outline,
                                          color: Color(0xFFDF3030),
                                        ),
                                        border: InputBorder.none,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 18,
                                            ),
                                      ),
                                    );
                                  },
                              optionsViewBuilder:
                                  (context, onSelected, options) {
                                    return Align(
                                      alignment: Alignment.topLeft,
                                      child: Material(
                                        elevation: 8.0,
                                        borderRadius: BorderRadius.circular(15),
                                        child: SizedBox(
                                          width: 300,
                                          child: ListView(
                                            padding: EdgeInsets.zero,
                                            shrinkWrap: true,
                                            children: options
                                                .map(
                                                  (String option) => ListTile(
                                                    title: Text(
                                                      option,
                                                      style: TextStyle(
                                                        color: Colors
                                                            .grey
                                                            .shade800,
                                                      ),
                                                    ),
                                                    onTap: () =>
                                                        onSelected(option),
                                                  ),
                                                )
                                                .toList(),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                            ),
                          ),
                          const SizedBox(height: 30),

                          // --- PIN INDICATORS ---
                          Text(
                            "Enter 6-Digit PIN".tr,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Obx(
                            () => Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(6, (index) {
                                bool isActive = index < controller.pin.length;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isActive
                                        ? const Color(0xFFDF3030)
                                        : neuBackground,
                                    boxShadow: isActive
                                        ? [
                                            // Active glowing state
                                            BoxShadow(
                                              color: const Color(
                                                0xFFDF3030,
                                              ).withValues(alpha: 0.5),
                                              blurRadius: 10,
                                              spreadRadius: 2,
                                            ),
                                          ]
                                        : const [
                                            // Inactive raised state
                                            BoxShadow(
                                              color: neuShadowDark,
                                              offset: Offset(3, 3),
                                              blurRadius: 5,
                                            ),
                                            BoxShadow(
                                              color: neuShadowLight,
                                              offset: Offset(-3, -3),
                                              blurRadius: 5,
                                            ),
                                          ],
                                  ),
                                );
                              }),
                            ),
                          ),

                          // --- KEYPAD ---
                          SizedBox(
                            width: 300,
                            height: 400,
                            child: GridView.builder(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    childAspectRatio: 1.2,
                                  ),
                              itemCount: 12,
                              physics: const NeverScrollableScrollPhysics(),
                              itemBuilder: (context, index) {
                                const keys = [
                                  '1',
                                  '2',
                                  '3',
                                  '4',
                                  '5',
                                  '6',
                                  '7',
                                  '8',
                                  '9',
                                  'CLEAR',
                                  '0',
                                  '<',
                                ];
                                final key = keys[index];
                                final isClearKey = key == 'CLEAR';

                                return GestureDetector(
                                  onTap: () {
                                    if (key == '<') {
                                      controller.onBackspaceTapped();
                                    } else if (key == 'CLEAR') {
                                      controller.usernameController.clear();
                                      for (int i = 0; i < 6; i++) {
                                        controller.onBackspaceTapped();
                                      }
                                    } else {
                                      controller.onKeypadTapped(key);
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: neuBackground,
                                      boxShadow: const [
                                        BoxShadow(
                                          color: neuShadowDark,
                                          offset: Offset(6, 6),
                                          blurRadius: 12,
                                        ),
                                        BoxShadow(
                                          color: neuShadowLight,
                                          offset: Offset(-6, -6),
                                          blurRadius: 12,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: key == '<'
                                          ? Icon(
                                              Icons.backspace_outlined,
                                              color: Colors.grey.shade700,
                                            )
                                          : Text(
                                              key,
                                              style: TextStyle(
                                                fontSize: isClearKey ? 14 : 26,
                                                fontWeight: FontWeight.bold,
                                                color: isClearKey
                                                    ? const Color(0xFFDF3030)
                                                    : Colors.grey.shade800,
                                              ),
                                            ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper to map languageCode to Locale
  Locale _localeFromCode(String code) {
    switch (code) {
      case 'zh':
        return const Locale('zh', 'CN');
      case 'ms':
        return const Locale('ms', 'MY');
      default:
        return const Locale('en', 'US');
    }
  }
}
