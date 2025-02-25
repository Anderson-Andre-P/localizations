import 'package:flutter/material.dart';
import 'package:localizations/location_helper.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Minha Localização',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3498DB),
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3498DB),
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      themeMode: ThemeMode.system,
      home: const LocationScreen(),
    );
  }
}

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen>
    with SingleTickerProviderStateMixin {
  final LocationHelper _locationHelper = LocationHelper();

  LocationData? _locationData;
  LocationError? _error;
  bool _isLoading = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animationController.repeat(reverse: true);
    _getUserLocation();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _locationHelper.getUserLocation();

    setState(() {
      _isLoading = false;
      if (result.isSuccess) {
        _locationData = result.data;
      } else {
        _error = result.error;
      }
    });
  }

  void _handleLocationError() async {
    switch (_error) {
      case LocationError.serviceDisabled:
        await _locationHelper.openLocationSettings();
        break;
      case LocationError.permissionDenied:
      case LocationError.permissionDeniedForever:
        await _locationHelper.openAppSettings();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Minha Localização',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
      ),
      body: RefreshIndicator(
        onRefresh: _getUserLocation,
        child: Stack(
          children: [
            if (_isLoading)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset(
                      'assets/location_loading.json',
                      width: 200,
                      height: 200,
                      controller: _animationController,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Buscando sua localização...',
                      style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              )
            else if (_error != null)
              _buildErrorWidget()
            else if (_locationData != null)
              _buildLocationContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationContent() {
    final data = _locationData!;
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cartão principal com cidade e país
          Card(
            elevation: 4,
            shadowColor: colorScheme.primary.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.location_on_rounded,
                          color: colorScheme.primary,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data.city,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              data.country,
                              style: TextStyle(
                                fontSize: 16,
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 30),
                  Text(
                    data.address,
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _launchUrl,
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Abrir no Google Maps'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Seção para os detalhes da localização
          Text(
            'Detalhes da Localização',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.start,
          ),

          const SizedBox(height: 16),

          // Coordenadas em um grid de cartões
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildInfoCard(
                'Latitude',
                '${data.latitude.toStringAsFixed(6)}°',
                Icons.compass_calibration,
              ),
              _buildInfoCard(
                'Longitude',
                '${data.longitude.toStringAsFixed(6)}°',
                Icons.explore,
              ),
              if (data.altitude != null)
                _buildInfoCard(
                  'Altitude',
                  '${data.altitude!.toStringAsFixed(1)} m',
                  Icons.height,
                ),
              if (data.accuracy != null)
                _buildInfoCard(
                  'Precisão',
                  '${data.accuracy!.toStringAsFixed(1)} m',
                  Icons.gps_fixed,
                ),
              _buildInfoCard(
                'Estado',
                data.administrative,
                Icons.account_balance,
              ),
              _buildInfoCard(
                'Cidade',
                data.city,
                Icons.location_city,
              ),
              _buildInfoCard(
                'Rua',
                data.street.toString(),
                Icons.report_gmailerrorred_rounded,
              ),
              _buildInfoCard(
                'CEP',
                data.postalCode,
                Icons.markunread_mailbox,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Botão para atualizar localização
          FilledButton.icon(
            onPressed: _getUserLocation,
            icon: const Icon(Icons.refresh),
            label: const Text('Atualizar Localização'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Future<void> _launchUrl() async {
    final lat = _locationData!.latitude;
    final lng = _locationData!.longitude;
    final Uri url =
        Uri.parse('https://www.google.com/maps/@?api=1&map_action=map$lat$lng');

    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: colorScheme.primary,
              size: 28,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    String errorMessage;
    String buttonText;
    IconData errorIcon;

    switch (_error) {
      case LocationError.serviceDisabled:
        errorMessage =
            'O serviço de localização está desativado no seu dispositivo.';
        buttonText = 'Abrir Configurações';
        errorIcon = Icons.location_off;
        break;
      case LocationError.permissionDenied:
      case LocationError.permissionDeniedForever:
        errorMessage =
            'Permissão de localização negada. Por favor, habilite o acesso à localização para usar este app.';
        buttonText = 'Abrir Configurações';
        errorIcon = Icons.no_accounts;
        break;
      case LocationError.networkError:
        errorMessage =
            'Sem conexão com a internet. Verifique sua conexão e tente novamente.';
        buttonText = 'Tentar Novamente';
        errorIcon = Icons.wifi_off;
        break;
      default:
        errorMessage =
            'Ocorreu um erro ao obter sua localização. Tente novamente.';
        buttonText = 'Tentar Novamente';
        errorIcon = Icons.error_outline;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              errorIcon,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 24),
            Text(
              errorMessage,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _error == LocationError.serviceDisabled ||
                      _error == LocationError.permissionDenied ||
                      _error == LocationError.permissionDeniedForever
                  ? _handleLocationError
                  : _getUserLocation,
              icon: Icon(_error == LocationError.serviceDisabled ||
                      _error == LocationError.permissionDenied ||
                      _error == LocationError.permissionDeniedForever
                  ? Icons.settings
                  : Icons.refresh),
              label: Text(buttonText),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
