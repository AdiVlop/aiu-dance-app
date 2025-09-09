import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

class MetaApiService {
  static const String _baseUrl = 'https://graph.facebook.com/v18.0';
  
  // Configurări Meta API
  static String? _accessToken;
  static String? _pageId;
  static String? _instagramAccountId;
  
  /// Inițializează serviciul cu token-ul și ID-urile din Settings
  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString('meta_access_token');
      _pageId = prefs.getString('meta_page_id');
      _instagramAccountId = prefs.getString('meta_instagram_id');
      
      Logger.info('Meta API Service initialized');
    } catch (e) {
      Logger.error('Error initializing Meta API Service: $e');
    }
  }

  /// Verifică dacă serviciul este configurat corect
  static bool get isConfigured {
    return _accessToken != null && 
           _accessToken!.isNotEmpty && 
           _pageId != null && 
           _pageId!.isNotEmpty;
  }

  /// Testează conexiunea la Meta API
  static Future<Map<String, dynamic>> testConnection() async {
    try {
      if (!isConfigured) {
        return {
          'success': false,
          'message': 'Meta API nu este configurat. Verifică Settings.',
        };
      }

      // Testează accesul la pagina Facebook
      final response = await http.get(
        Uri.parse('$_baseUrl/$_pageId?fields=name,access_token&access_token=$_accessToken'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Conexiunea Meta API funcționează!',
          'page_name': data['name'],
        };
      } else {
        return {
          'success': false,
          'message': 'Eroare la testarea conexiunii: ${response.statusCode}',
        };
      }
    } catch (e) {
      Logger.error('Error testing Meta API connection: $e');
      return {
        'success': false,
        'message': 'Eroare la testarea conexiunii: $e',
      };
    }
  }

  /// Publică anunț pe Facebook
  static Future<Map<String, dynamic>> publishToFacebook({
    required String title,
    required String content,
    String? imageUrl,
    String? appUrl,
  }) async {
    try {
      if (!isConfigured) {
        return {
          'success': false,
          'message': 'Meta API nu este configurat',
        };
      }

      // Construiește caption-ul
      String caption = '$title\n\n$content';
      if (appUrl != null) {
        caption += '\n\n🌐 Aplicația: $appUrl';
      }
      caption += '\n\n💃 #AIUDance #Dans #Cursuri';

      Map<String, dynamic> postData = {
        'access_token': _accessToken,
      };

      String endpoint;
      
      if (imageUrl != null && imageUrl.isNotEmpty) {
        // Post cu imagine
        endpoint = '$_baseUrl/$_pageId/photos';
        postData.addAll({
          'url': imageUrl,
          'caption': caption,
        });
      } else {
        // Post doar cu text
        endpoint = '$_baseUrl/$_pageId/feed';
        postData.addAll({
          'message': caption,
        });
      }

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: postData.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}').join('&'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        Logger.info('Facebook post created successfully: ${data['post_id'] ?? data['id']}');
        return {
          'success': true,
          'message': 'Anunț publicat pe Facebook!',
          'post_id': data['post_id'] ?? data['id'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        Logger.error('Facebook API error: ${errorData['error']['message']}');
        return {
          'success': false,
          'message': 'Eroare Facebook: ${errorData['error']['message']}',
        };
      }
    } catch (e) {
      Logger.error('Error publishing to Facebook: $e');
      return {
        'success': false,
        'message': 'Eroare la publicarea pe Facebook: $e',
      };
    }
  }

  /// Publică anunț pe Instagram
  static Future<Map<String, dynamic>> publishToInstagram({
    required String title,
    required String content,
    String? imageUrl,
    String? appUrl,
  }) async {
    try {
      if (!isConfigured || _instagramAccountId == null) {
        return {
          'success': false,
          'message': 'Instagram nu este configurat',
        };
      }

      if (imageUrl == null || imageUrl.isEmpty) {
        return {
          'success': false,
          'message': 'Instagram necesită o imagine',
        };
      }

      // Construiește caption-ul pentru Instagram
      String caption = '$title\n\n$content';
      if (appUrl != null) {
        caption += '\n\n🌐 Link în bio';
      }
      caption += '\n\n💃 #AIUDance #Dans #Cursuri #DansRomania #Salsa #Bachata';

      // Pas 1: Creează media container
      final mediaResponse = await http.post(
        Uri.parse('$_baseUrl/$_instagramAccountId/media'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'image_url': imageUrl,
          'caption': caption,
          'access_token': _accessToken,
        }.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}').join('&'),
      );

      if (mediaResponse.statusCode != 200) {
        final errorData = jsonDecode(mediaResponse.body);
        return {
          'success': false,
          'message': 'Eroare la crearea media Instagram: ${errorData['error']['message']}',
        };
      }

      final mediaData = jsonDecode(mediaResponse.body);
      final creationId = mediaData['id'];

      // Pas 2: Publică media
      final publishResponse = await http.post(
        Uri.parse('$_baseUrl/$_instagramAccountId/media_publish'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'creation_id': creationId,
          'access_token': _accessToken,
        }.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}').join('&'),
      );

      if (publishResponse.statusCode == 200) {
        final publishData = jsonDecode(publishResponse.body);
        Logger.info('Instagram post created successfully: ${publishData['id']}');
        return {
          'success': true,
          'message': 'Anunț publicat pe Instagram!',
          'post_id': publishData['id'],
        };
      } else {
        final errorData = jsonDecode(publishResponse.body);
        return {
          'success': false,
          'message': 'Eroare la publicarea pe Instagram: ${errorData['error']['message']}',
        };
      }
    } catch (e) {
      Logger.error('Error publishing to Instagram: $e');
      return {
        'success': false,
        'message': 'Eroare la publicarea pe Instagram: $e',
      };
    }
  }

  /// Publică pe ambele platforme (Facebook + Instagram)
  static Future<Map<String, dynamic>> publishToBoth({
    required String title,
    required String content,
    String? imageUrl,
    String? appUrl,
  }) async {
    try {
      final results = <String, dynamic>{
        'facebook': {'success': false},
        'instagram': {'success': false},
      };

      // Publică pe Facebook
      final fbResult = await publishToFacebook(
        title: title,
        content: content,
        imageUrl: imageUrl,
        appUrl: appUrl,
      );
      results['facebook'] = fbResult;

      // Publică pe Instagram (doar dacă avem imagine)
      if (imageUrl != null && imageUrl.isNotEmpty) {
        final igResult = await publishToInstagram(
          title: title,
          content: content,
          imageUrl: imageUrl,
          appUrl: appUrl,
        );
        results['instagram'] = igResult;
      }

      // Calculează rezultatul general
      final fbSuccess = results['facebook']['success'] == true;
      final igSuccess = results['instagram']['success'] == true;

      String message;
      if (fbSuccess && igSuccess) {
        message = 'Anunț publicat pe Facebook și Instagram!';
      } else if (fbSuccess) {
        message = 'Anunț publicat pe Facebook!';
      } else if (igSuccess) {
        message = 'Anunț publicat pe Instagram!';
      } else {
        message = 'Eroare la publicare pe ambele platforme';
      }

      return {
        'success': fbSuccess || igSuccess,
        'message': message,
        'results': results,
      };
    } catch (e) {
      Logger.error('Error publishing to both platforms: $e');
      return {
        'success': false,
        'message': 'Eroare la publicarea pe rețelele sociale: $e',
      };
    }
  }

  /// Obține informații despre pagina Facebook
  static Future<Map<String, dynamic>?> getPageInfo() async {
    try {
      if (!isConfigured) return null;

      final response = await http.get(
        Uri.parse('$_baseUrl/$_pageId?fields=name,followers_count,fan_count&access_token=$_accessToken'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      Logger.error('Error getting page info: $e');
      return null;
    }
  }

  /// Obține informații despre contul Instagram
  static Future<Map<String, dynamic>?> getInstagramInfo() async {
    try {
      if (!isConfigured || _instagramAccountId == null) return null;

      final response = await http.get(
        Uri.parse('$_baseUrl/$_instagramAccountId?fields=name,followers_count,media_count&access_token=$_accessToken'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      Logger.error('Error getting Instagram info: $e');
      return null;
    }
  }

  /// Setează configurările Meta API
  static Future<void> setConfiguration({
    required String accessToken,
    required String pageId,
    String? instagramAccountId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setString('meta_access_token', accessToken);
      await prefs.setString('meta_page_id', pageId);
      if (instagramAccountId != null) {
        await prefs.setString('meta_instagram_id', instagramAccountId);
      }

      _accessToken = accessToken;
      _pageId = pageId;
      _instagramAccountId = instagramAccountId;

      Logger.info('Meta API configuration saved');
    } catch (e) {
      Logger.error('Error saving Meta API configuration: $e');
    }
  }

  /// Obține configurările curente
  static Map<String, String?> getConfiguration() {
    return {
      'access_token': _accessToken,
      'page_id': _pageId,
      'instagram_id': _instagramAccountId,
    };
  }
}






