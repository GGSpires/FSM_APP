/*
EXAMPLE OF IMPORTING THE EXPORT BARREL FILE
import 'package:fsm_app/export.dart';

FOR GITHUB, the 3 steps to update the REPO is
  1) git add .
  2) git commit
  3) git push origin main
 */

//Flutter
export 'package:flutter/material.dart';
export 'package:flutter/services.dart';
export 'package:flutter/foundation.dart';

//Dart
export 'dart:convert';
export 'dart:io';
export 'dart:async';
export 'dart:typed_data';
export 'dart:core';

//Dependencies
export 'package:image_picker/image_picker.dart';
export 'package:shared_preferences/shared_preferences.dart';
export 'package:signature/signature.dart';
export 'package:package_info_plus/package_info_plus.dart';
export 'package:yaml/yaml.dart';
export 'package:date_field/date_field.dart';

/*
==============================================================================================================================
CORE
==============================================================================================================================
*/
//-api
export 'package:fsm_app/core/api/api_client.dart';
//-constants
export 'package:fsm_app/core/constants/api_constants.dart';
//-theme
export 'package:fsm_app/core/theme/app_theme.dart';
export 'package:fsm_app/core/theme/theme_provider.dart';
//-utils

/*
==============================================================================================================================
FEATURES
==============================================================================================================================
*/
//AUTH
//--models
export 'package:fsm_app/features/auth/models/user_model.dart';
//--screens
export 'package:fsm_app/features/auth/screens/login_screen.dart';
export 'package:fsm_app/features/auth/screens/sign_up_screen.dart';
//--services
export 'package:fsm_app/features/auth/services/auth_provider.dart';
//--widgets

//CLIENTS
//--models
export 'package:fsm_app/features/clients/models/client_model.dart';
//--screens
//--services
//--widgets

//HOME
//--screens
export 'package:fsm_app/features/home/screens/home_screen.dart';
//--widgets

//JOB_CARDS
//--models
export 'package:fsm_app/features/job_cards/models/job_card_model.dart';
//--screens
export 'features/job_cards/screens/job_card_form_screen.dart';
export 'features/job_cards/screens/job_card_list_screen.dart';
//--services
//--widgets

//SETTINGS
//--models
//--screens
export 'features/settings/screens/user_settings_screen.dart';
//--services
//--widgets

//STOCK_INVENTORY
//--models
export 'package:fsm_app/features/stock_inventory/models/stock_item_model.dart';
//--screens
export 'features/stock_inventory/screens/stock_inventory_screen.dart';
//--services
//--widgets

/*
==============================================================================================================================
SHARED
==============================================================================================================================
*/
//-dialog
//-widgets

/*
==============================================================================================================================
MAIN
==============================================================================================================================
*/
export 'package:fsm_app/main.dart';
