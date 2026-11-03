import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equity_tracker/features/ai/domain/models/ai_provider_config.dart';
import 'package:equity_tracker/features/ai/presentation/controllers/ai_config_controller.dart';
import 'package:equity_tracker/core/theme/app_colors.dart';
import 'package:equity_tracker/core/widgets/app_switch.dart';
import 'package:equity_tracker/core/widgets/premium_config_card.dart';
import 'package:equity_tracker/core/widgets/premium_config_header.dart';
import 'package:equity_tracker/core/widgets/immersive_scaffold.dart';
import 'package:equity_tracker/core/widgets/sheet/lens_wise_sheet_handle.dart';

class AiSettingsScreen extends ConsumerStatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  ConsumerState<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends ConsumerState<AiSettingsScreen> {
  late TextEditingController _modelNameController;
  late TextEditingController _baseUrlController;
  late TextEditingController _projectIdController;
  late TextEditingController _regionController;
  late TextEditingController _accessTokenController;
  late TextEditingController _googleMapApiController;
  
  AIProviderType? _lastProviderType;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _modelNameController = TextEditingController();
    _baseUrlController = TextEditingController();
    _projectIdController = TextEditingController();
    _regionController = TextEditingController();
    _accessTokenController = TextEditingController();
    _googleMapApiController = TextEditingController();
  }

  @override
  void dispose() {
    _modelNameController.dispose();
    _baseUrlController.dispose();
    _projectIdController.dispose();
    _regionController.dispose();
    _accessTokenController.dispose();
    _googleMapApiController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _syncControllers(AIConfigState state) {
    if (_lastProviderType == state.providerType) return;
    _lastProviderType = state.providerType;
    
    final config = state.activeConfig;
    
    if (_modelNameController.text != config.modelName) {
      _modelNameController.text = config.modelName;
    }
    
    if (_googleMapApiController.text != state.googleMapApiKey) {
      _googleMapApiController.text = state.googleMapApiKey;
    }

    if (config is GeminiFlowConfig) {
      if (_baseUrlController.text != config.baseUrl) _baseUrlController.text = config.baseUrl;
    } else if (config is OllamaConfig) {
      if (_baseUrlController.text != config.baseUrl) _baseUrlController.text = config.baseUrl;
    } else if (config is VertexAIConfig) {
      if (_projectIdController.text != config.projectId) _projectIdController.text = config.projectId;
      if (_regionController.text != config.region) _regionController.text = config.region;
      if (_accessTokenController.text != config.accessToken) _accessTokenController.text = config.accessToken;
    }
  }

  void _onFieldChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      final state = ref.read(aiConfigControllerProvider);
      final config = state.activeConfig;
      
      ProviderConfig newConfig = config;
      if (config is GeminiFlowConfig) {
        newConfig = config.copyWith(
          modelName: _modelNameController.text,
          baseUrl: _baseUrlController.text,
        );
      } else if (config is OllamaConfig) {
        newConfig = config.copyWith(
          modelName: _modelNameController.text,
          baseUrl: _baseUrlController.text,
        );
      } else if (config is VertexAIConfig) {
        newConfig = config.copyWith(
          modelName: _modelNameController.text,
          projectId: _projectIdController.text,
          region: _regionController.text,
          accessToken: _accessTokenController.text,
        );
      }

      ref.read(aiConfigControllerProvider.notifier).saveConfig(
        activeProviderConfig: newConfig,
        googleMapApiKey: _googleMapApiController.text,
      );
    });
  }

  void _onAIAgentToggle(bool value) {
    ref.read(aiConfigControllerProvider.notifier).saveConfig(isAIAgentEnabled: value);
  }

  void _onGoogleMapToggle(bool value) {
    ref.read(aiConfigControllerProvider.notifier).saveConfig(isGoogleMapEnabled: value);
  }

  IconData _getProviderIcon(AIProviderType type) {
    if (type == AIProviderType.geminiflow) return Icons.auto_awesome;
    if (type == AIProviderType.ollama) return Icons.memory_rounded;
    return Icons.cloud_done_rounded;
  }



  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 10, top: 24),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
          color: isDark ? Colors.white54 : Colors.black54,
        ),
      ),
    );
  }

  void _showProviderSelectorBottomSheet(AIConfigState state, bool isDark) {
    final titleColor = isDark
        ? Colors.white.withOpacity(0.54)
        : Colors.black.withOpacity(0.54);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. LensWise 頂部把手 (32dp 置中)
                  LensWiseSheetHandle(isDark: isDark),

                  // 2. LensWise Header 導航列 (1:1 左右對稱 + 13sp 字距 2.0 粗體置中標題)
                  Row(
                    children: [
                      const SizedBox(width: 48), // 左側 Spacer 平衡
                      Expanded(
                        child: Text(
                          'AI ENGINE',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                            color: titleColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // 右側 Spacer 平衡
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...AIProviderType.values.map((type) {
                    final isSelected = state.providerType == type;
                    return ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      tileColor: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : null,
                      leading: Icon(
                        _getProviderIcon(type),
                        color: isSelected ? Theme.of(context).primaryColor : (isDark ? Colors.white54 : Colors.black54),
                      ),
                      title: Text(
                        type.name.toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Theme.of(context).primaryColor : (isDark ? Colors.white : Colors.black),
                        ),
                      ),
                      trailing: isSelected 
                        ? Icon(Icons.check_circle_rounded, color: Theme.of(context).primaryColor)
                        : null,
                      onTap: () {
                        _lastProviderType = null;
                        ref.read(aiConfigControllerProvider.notifier).saveConfig(providerType: type);
                        Navigator.pop(context);
                      },
                    );
                  }),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildSmartSelectorCard(AIConfigState state, bool isDark) {
    final type = state.providerType;
    final isEnabled = state.isAIAgentEnabled;
    return GestureDetector(
      onTap: isEnabled ? () => _showProviderSelectorBottomSheet(state, isDark) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        color: Colors.transparent,
        child: Opacity(
          opacity: isEnabled ? 1.0 : 0.4,
          child: Row(
            children: [
              Container(
                constraints: const BoxConstraints(minWidth: 50),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Icon(
                  _getProviderIcon(type),
                  color: Theme.of(context).primaryColor,
                  size: 22,
                ),
              ),
              Expanded(
                child: Text(
                  type.name.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile(String hint, IconData icon, TextEditingController controller, bool isDark, {bool obscureText = false, bool isEnabled = true}) {
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.4,
      child: TextFormField(
        controller: controller,
        onChanged: (_) => _onFieldChanged(),
        obscureText: obscureText,
        enabled: isEnabled,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 16,
          color: isDark ? Colors.white : Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontFamily: 'Outfit',
            color: isDark ? Colors.white30 : Colors.black38,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Icon(
              icon,
              color: Theme.of(context).primaryColor,
              size: 22,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 50, minHeight: 50),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 60),
      child: Divider(
        height: 1,
        thickness: 0.5,
        color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05),
      ),
    );
  }

  List<Widget> _buildParameterFields(AIConfigState state, bool isDark) {
    final List<Widget> fields = [];
    final isEnabled = state.isAIAgentEnabled;
    
    fields.add(_buildDivider(isDark));
    fields.add(_buildSettingsTile('Model Name', Icons.smart_toy_rounded, _modelNameController, isDark, isEnabled: isEnabled));
    
    if (state.activeConfig is VertexAIConfig) {
      fields.add(_buildDivider(isDark));
      fields.add(_buildSettingsTile('Project ID', Icons.business_rounded, _projectIdController, isDark, isEnabled: isEnabled));
      fields.add(_buildDivider(isDark));
      fields.add(_buildSettingsTile('Region', Icons.public_rounded, _regionController, isDark, isEnabled: isEnabled));
      fields.add(_buildDivider(isDark));
      fields.add(_buildSettingsTile('Access Token', Icons.key_rounded, _accessTokenController, isDark, obscureText: true, isEnabled: isEnabled));
    } else {
      fields.add(_buildDivider(isDark));
      fields.add(_buildSettingsTile('Base URL', Icons.dns_rounded, _baseUrlController, isDark, isEnabled: isEnabled));
    }
    
    return fields;
  }

  Widget _buildAnimatedParametersGroup(AIConfigState state, bool isDark) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutQuart,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.05),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: Column(
          key: ValueKey(state.providerType),
          children: _buildParameterFields(state, isDark),
        ),
      ),
    );
  }

  Widget _buildGlobalSettingsGroup(AIConfigState state, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Global Integrations', isDark),
        PremiumConfigCard(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Google Map API',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    AppSwitch(
                      value: state.isGoogleMapEnabled,
                      onChanged: _onGoogleMapToggle,
                      activeColor: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
              ),
              _buildDivider(isDark),
              _buildSettingsTile(
                'Google Map API Key (Optional)',
                Icons.map_rounded,
                _googleMapApiController,
                isDark,
                obscureText: true,
                isEnabled: state.isGoogleMapEnabled,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiConfigControllerProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    _syncControllers(state);

    return ImmersiveScaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PremiumConfigHeader(
              title: 'AI Engine\nConfiguration',
              subtitle: 'SMART CATEGORIZATION & INSIGHTS',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildGlobalSettingsGroup(state, isDark),
                  const SizedBox(height: 24),
                  
                  _buildSectionHeader('AI Engine', isDark),
                  PremiumConfigCard(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'AI Agent',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        AppSwitch(
                          value: state.isAIAgentEnabled,
                          onChanged: _onAIAgentToggle,
                          activeColor: Theme.of(context).primaryColor,
                        ),
                      ],
                    ),
                  ),
                  _buildDivider(isDark),
                  _buildSmartSelectorCard(state, isDark),
                  _buildAnimatedParametersGroup(state, isDark),
                ],
              ),
            ),
            const SizedBox(height: 60),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
