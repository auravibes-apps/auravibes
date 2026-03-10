// DO NOT EDIT. This is code generated via package:easy_localization/generate.dart

// ignore_for_file: prefer_single_quotes, avoid_renaming_method_parameters, constant_identifier_names

import 'dart:ui';

import 'package:easy_localization/easy_localization.dart' show AssetLoader;

class CodegenLoader extends AssetLoader{
  const CodegenLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) {
    return Future.value(mapLocales[locale.toString()]);
  }

  static const Map<String,dynamic> _en = {
  "menu": {
    "home": "Home",
    "new_chat": "New Chat",
    "chats": "Chats",
    "tools": "Tools",
    "models": "Models",
    "agents": "Agents",
    "prompts": "Prompts"
  },
  "models_screens": {
    "title": "Model Providers",
    "list_error": "Error loading models: {}",
    "list_empty_title": "No AI Models Configured",
    "list_empty_subtitle": "Add your first AI model to get started",
    "list_url_label": "URL: {}",
    "list_api_key_label": "API Key: {}",
    "list_delete_title": "Delete Model Provider",
    "list_delete_confirm": "Are you sure you want to delete {name}?",
    "add_provider": {
      "open_button": "Add Provider",
      "title": "Add Model Provider",
      "create_button": "Create Provider",
      "sections": {
        "advanced": "Advanced"
      },
      "fields": {
        "name": {
          "label": "Name",
          "placeholder": "Enter provider name",
          "hint": "Choose a descriptive name for this provider"
        },
        "key": {
          "label": "API Key",
          "placeholder": "Enter your API key",
          "hint": "Your personal API key from the provider"
        },
        "url": {
          "label": "Custom URL",
          "placeholder": "https://api.example.com (optional)",
          "hint": "Custom API endpoint (leave empty for default)"
        }
      },
      "search": {
        "placeholder": "Search model providers...",
        "no_models_found": "No model providers found",
        "no_icon": "No icon"
      }
    }
  },
  "chats_screens": {
    "chats_list": {
      "title": "Chats",
      "add_chat": "Add Chat"
    },
    "chat_conversation": {
      "select_model_selctor": "Select Model",
      "message_placeholder": "Type your message...",
      "waiting_for_tools": "Waiting for tools to connect...",
      "waiting_for_tools_named": "Waiting for {tools} to connect...",
      "delete_title": "Delete Conversation",
      "delete_confirm": "Are you sure you want to delete this conversation? This action cannot be undone.",
      "delete_tooltip": "Delete conversation"
    }
  },
  "tools_screen": {
    "title": "Workspace Tools",
    "refresh_tooltip": "Refresh tools",
    "workspace_ai_tools": "Workspace AI Tools",
    "enable_configure_description": "Enable and configure tools for this workspace",
    "enabled_count": {
      "zero": "no tools enabled",
      "other": "{} enabled"
    },
    "configured": "Configured",
    "add_tool_title": "Add Tool",
    "add_tool_tooltip": "Add a new tool",
    "search_tools": "Search tools...",
    "no_tools_added": "No tools added",
    "add_tools_hint": "Tap the + button to add tools to this workspace",
    "all_tools_added": "All available tools have been added",
    "no_tools_found": "No tools match your search",
    "remove_tool_title": "Remove Tool",
    "remove_tool_confirm": "Are you sure you want to remove this tool from the workspace?",
    "remove_tool_tooltip": "Remove tool",
    "permission_always_ask": "Always Ask",
    "permission_always_allow": "Always Allow",
    "permission_label": "Permission",
    "enabled_label": "Enabled",
    "default_group": "Built-in Tools",
    "mcp_connecting": "Connecting...",
    "mcp_connected": "Connected",
    "mcp_error": "Connection failed",
    "mcp_disconnected": "Disconnected",
    "mcp_reconnect": "Reconnect",
    "mcp_view_error": "View details",
    "tools_count": "{enabled} of {total} enabled",
    "delete_mcp_title": "Delete MCP Server",
    "delete_mcp_confirm": "This will remove the MCP server and all its tools. Continue?",
    "no_tools_in_group": "No tools available"
  },
  "tool_confirmation": {
    "allow_once": "Allow Once",
    "allow_conversation": "Allow for Conversation",
    "skip": "Skip",
    "stop_all": "Stop All"
  },
  "tool_call_status": {
    "success": "Completed",
    "skipped_by_user": "Skipped",
    "stopped_by_user": "Stopped",
    "tool_not_found": "Tool not found",
    "disabled_in_workspace": "Disabled in workspace",
    "disabled_in_conversation": "Disabled in conversation",
    "not_configured": "Not configured",
    "execution_error": "Execution failed",
    "running": "Running...",
    "pending": "Awaiting confirmation"
  },
  "common": {
    "cancel": "Cancel",
    "remove": "Remove",
    "add": "Add",
    "save": "Save",
    "delete": "Delete",
    "confirm": "Confirm",
    "close": "Close",
    "show_more": "Show more"
  },
  "tools_names": {
    "calculator": {
      "name": "Calculator",
      "description": "Solve Math problems"
    }
  },
  "home_screen": {
    "welcome_title": "Welcome to AuraVibes",
    "welcome_subtitle": "Your AI assistant is ready to help",
    "quick_actions": "Quick Actions",
    "recent_conversations": "Recent Conversations",
    "actions": {
      "start_new_chat": "Start New Chat",
      "all_chats": "All Chats",
      "settings": "Settings",
      "models": "Models",
      "tools": "Tools",
      "agents": "Agents"
    },
    "conversation_states": {
      "no_conversations": "No conversations yet",
      "no_chats_yet": "No Chats Yet",
      "start_first_conversation": "Start your first conversation with AuraVibes",
      "error_loading_conversations": "Error loading conversations: {}",
      "error_loading_chats": "Error loading chats: {}"
    },
    "date_formatting": {
      "just_now": "Just now",
      "minutes_ago": "{}m ago",
      "hours_ago": "{}h ago",
      "days_ago": "{}d ago"
    }
  },
  "status_bar": {
    "models_available": {
      "zero": "No models available",
      "one": "{} model available",
      "other": "{} models available"
    },
    "loading_models": "Loading models...",
    "model_error": "Model error",
    "api_connected": "API Connected"
  },
  "settings_screen": {
    "title": "Settings",
    "app_settings": {
      "title": "App Settings",
      "subtitle": "Configure your app preferences and behavior"
    },
    "theme": {
      "title": "Theme & Appearance",
      "light": "Light",
      "dark": "Dark",
      "system": "System",
      "system_default": "System Default"
    },
    "actions": {
      "cancel": "Cancel"
    }
  },
  "sidebar": {
    "recent_chats": "Recent Chats",
    "no_recent_chats": "No recent chats",
    "view_all_chats": "View All"
  },
  "mcp_modal": {
    "title": "Add MCP Server",
    "add_mcp_tooltip": "Add MCP Server",
    "transport": {
      "sse": "SSE",
      "streamable_http": "Streamable HTTP"
    },
    "auth": {
      "none": "None",
      "oauth": "OAuth",
      "bearer_token": "Bearer Token"
    },
    "oauth_section_title": "OAuth Configuration",
    "bearer_section_title": "Bearer Token",
    "fields": {
      "name": {
        "label": "Name",
        "placeholder": "My MCP Server"
      },
      "description": {
        "label": "Description (optional)",
        "placeholder": "What does this server provide?"
      },
      "url": {
        "label": "Server URL",
        "placeholder": "https://mcp.example.com",
        "hint": "The MCP server endpoint URL"
      },
      "transport": {
        "label": "Transport"
      },
      "authentication": {
        "label": "Authentication"
      },
      "use_http2": {
        "label": "Use HTTP/2",
        "hint": "Enable HTTP/2 protocol for better performance"
      },
      "client_id": {
        "label": "Client ID",
        "placeholder": "your-client-id"
      },
      "token_endpoint": {
        "label": "Token Endpoint",
        "placeholder": "https://auth.example.com/oauth/token"
      },
      "auth_endpoint": {
        "label": "Authorization Endpoint",
        "placeholder": "https://auth.example.com/oauth/authorize"
      },
      "bearer_token": {
        "label": "Bearer Token",
        "placeholder": "Enter your bearer token",
        "hint": "This token will be stored securely"
      }
    }
  }
};
static const Map<String,dynamic> _es = {
  "menu": {
    "home": "Inicio",
    "new_chat": "Nuevo Chat",
    "chats": "Chats",
    "tools": "Herramientas",
    "models": "Modelos",
    "agents": "Agentes",
    "prompts": "Prompts"
  },
  "models_screens": {
    "title": "Proveedores de Modelos",
    "list_error": "Error al cargar modelos: {}",
    "list_empty_title": "No hay Modelos de IA Configurados",
    "list_empty_subtitle": "Agrega tu primer modelo de IA para comenzar",
    "list_url_label": "URL: {}",
    "list_api_key_label": "Clave API: {}",
    "list_delete_title": "Eliminar Proveedor de Modelo",
    "list_delete_confirm": "¿Estás seguro de que deseas eliminar {name}?",
    "add_provider": {
      "open_button": "Agregar Proveedor",
      "title": "Agregar Proveedor de Modelo",
      "create_button": "Crear Proveedor",
      "sections": {
        "advanced": "Avanzado"
      },
      "fields": {
        "name": {
          "label": "Nombre",
          "placeholder": "Ingresa el nombre del proveedor",
          "hint": "Elige un nombre descriptivo para este proveedor"
        },
        "key": {
          "label": "Clave API",
          "placeholder": "Ingresa tu clave API",
          "hint": "Tu clave API personal del proveedor"
        },
        "url": {
          "label": "URL Personalizada",
          "placeholder": "https://api.ejemplo.com (opcional)",
          "hint": "Endpoint API personalizado (déjalo vacío para usar el predeterminado)"
        }
      },
      "search": {
        "placeholder": "Buscar proveedores de modelos...",
        "no_models_found": "No se encontraron proveedores de modelos",
        "no_icon": "Sin ícono"
      }
    }
  },
  "chats_screens": {
    "chats_list": {
      "title": "Chats",
      "add_chat": "Agregar Chat"
    },
    "chat_conversation": {
      "select_model_selctor": "Selecionar Modelo",
      "message_placeholder": "Escribe tu mensaje...",
      "waiting_for_tools": "Esperando a que las herramientas se conecten...",
      "waiting_for_tools_named": "Esperando a que {tools} se conecte...",
      "delete_title": "Eliminar Conversación",
      "delete_confirm": "¿Estás seguro de que deseas eliminar esta conversación? Esta acción no se puede deshacer.",
      "delete_tooltip": "Eliminar conversación"
    }
  },
  "tools_screen": {
    "title": "Herramientas del Espacio de Trabajo",
    "refresh_tooltip": "Actualizar herramientas",
    "workspace_ai_tools": "Herramientas IA del Espacio de Trabajo",
    "enable_configure_description": "Activa y configura herramientas para este espacio de trabajo",
    "enabled_count": {
      "zero": "No hay herramientas activadas",
      "other": "{} activadas"
    },
    "configured": "Configurado",
    "add_tool_title": "Agregar Herramienta",
    "add_tool_tooltip": "Agregar una nueva herramienta",
    "search_tools": "Buscar herramientas...",
    "no_tools_added": "No hay herramientas agregadas",
    "add_tools_hint": "Toca el botón + para agregar herramientas a este espacio de trabajo",
    "all_tools_added": "Todas las herramientas disponibles han sido agregadas",
    "no_tools_found": "Ninguna herramienta coincide con tu búsqueda",
    "remove_tool_title": "Eliminar Herramienta",
    "remove_tool_confirm": "¿Estás seguro de que deseas eliminar esta herramienta del espacio de trabajo?",
    "remove_tool_tooltip": "Eliminar herramienta",
    "permission_always_ask": "Siempre Preguntar",
    "permission_always_allow": "Siempre Permitir",
    "permission_label": "Permiso",
    "enabled_label": "Activado",
    "default_group": "Herramientas Integradas",
    "mcp_connecting": "Conectando...",
    "mcp_connected": "Conectado",
    "mcp_error": "Error de conexión",
    "mcp_disconnected": "Desconectado",
    "mcp_reconnect": "Reconectar",
    "mcp_view_error": "Ver detalles",
    "tools_count": "{enabled} de {total} activadas",
    "delete_mcp_title": "Eliminar Servidor MCP",
    "delete_mcp_confirm": "Esto eliminará el servidor MCP y todas sus herramientas. ¿Continuar?",
    "no_tools_in_group": "No hay herramientas disponibles"
  },
  "tool_confirmation": {
    "allow_once": "Permitir una vez",
    "allow_conversation": "Permitir en conversación",
    "skip": "Omitir",
    "stop_all": "Detener todo"
  },
  "tool_call_status": {
    "success": "Completado",
    "skipped_by_user": "Omitido",
    "stopped_by_user": "Detenido",
    "tool_not_found": "Herramienta no encontrada",
    "disabled_in_workspace": "Desactivada en espacio de trabajo",
    "disabled_in_conversation": "Desactivada en conversación",
    "not_configured": "No configurada",
    "execution_error": "Error de ejecución",
    "running": "Ejecutando...",
    "pending": "Esperando confirmación"
  },
  "common": {
    "cancel": "Cancelar",
    "remove": "Eliminar",
    "add": "Agregar",
    "save": "Guardar",
    "delete": "Borrar",
    "confirm": "Confirmar",
    "close": "Cerrar",
    "show_more": "Ver más"
  },
  "tools_names": {
    "calculator": {
      "name": "Calculadora",
      "description": "Resuelve Problemas Matematicos"
    }
  },
  "home_screen": {
    "welcome_title": "Bienvenido a AuraVibes",
    "welcome_subtitle": "Tu asistente de IA está listo para ayudarte",
    "quick_actions": "Acciones Rápidas",
    "recent_conversations": "Conversaciones Recientes",
    "actions": {
      "start_new_chat": "Iniciar Nuevo Chat",
      "all_chats": "Todos los Chats",
      "settings": "Configuración",
      "models": "Modelos",
      "tools": "Herramientas",
      "agents": "Agentes"
    },
    "conversation_states": {
      "no_conversations": "No hay conversaciones aún",
      "no_chats_yet": "No hay Chats aún",
      "start_first_conversation": "Inicia tu primera conversación con AuraVibes",
      "error_loading_conversations": "Error al cargar conversaciones: {}",
      "error_loading_chats": "Error al cargar chats: {}"
    },
    "date_formatting": {
      "just_now": "Ahora mismo",
      "minutes_ago": "hace {}m",
      "hours_ago": "hace {}h",
      "days_ago": "hace {}d"
    }
  },
  "status_bar": {
    "models_available": {
      "zero": "No hay modelos disponibles",
      "one": "{} modelo disponible",
      "other": "{} modelos disponibles"
    },
    "loading_models": "Cargando modelos...",
    "model_error": "Error de modelo",
    "api_connected": "API Conectada"
  },
  "settings_screen": {
    "title": "Configuración",
    "app_settings": {
      "title": "Configuración de la App",
      "subtitle": "Configura tus preferencias y comportamiento de la app"
    },
    "theme": {
      "title": "Tema y Apariencia",
      "light": "Claro",
      "dark": "Oscuro",
      "system": "Sistema",
      "system_default": "Predeterminado del Sistema"
    },
    "actions": {
      "cancel": "Cancelar"
    }
  },
  "sidebar": {
    "recent_chats": "Chats Recientes",
    "no_recent_chats": "No hay chats recientes",
    "view_all_chats": "Ver Todos"
  },
  "mcp_modal": {
    "title": "Agregar Servidor MCP",
    "add_mcp_tooltip": "Agregar Servidor MCP",
    "transport": {
      "sse": "SSE",
      "streamable_http": "HTTP Streamable"
    },
    "auth": {
      "none": "Ninguna",
      "oauth": "OAuth",
      "bearer_token": "Token Bearer"
    },
    "oauth_section_title": "Configuración OAuth",
    "bearer_section_title": "Token Bearer",
    "fields": {
      "name": {
        "label": "Nombre",
        "placeholder": "Mi Servidor MCP"
      },
      "description": {
        "label": "Descripción (opcional)",
        "placeholder": "¿Qué proporciona este servidor?"
      },
      "url": {
        "label": "URL del Servidor",
        "placeholder": "https://mcp.ejemplo.com",
        "hint": "La URL del endpoint del servidor MCP"
      },
      "transport": {
        "label": "Transporte"
      },
      "authentication": {
        "label": "Autenticación"
      },
      "use_http2": {
        "label": "Usar HTTP/2",
        "hint": "Habilitar protocolo HTTP/2 para mejor rendimiento"
      },
      "client_id": {
        "label": "ID de Cliente",
        "placeholder": "tu-client-id"
      },
      "token_endpoint": {
        "label": "Endpoint de Token",
        "placeholder": "https://auth.ejemplo.com/oauth/token"
      },
      "auth_endpoint": {
        "label": "Endpoint de Autorización",
        "placeholder": "https://auth.ejemplo.com/oauth/authorize"
      },
      "bearer_token": {
        "label": "Token Bearer",
        "placeholder": "Ingresa tu token bearer",
        "hint": "Este token se almacenará de forma segura"
      }
    }
  }
};
static const Map<String, Map<String,dynamic>> mapLocales = {"en": _en, "es": _es};
}
