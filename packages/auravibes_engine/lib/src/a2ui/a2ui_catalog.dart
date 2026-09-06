/// Icon names advertised by both chat catalogs. Legacy strings remain accepted.
const a2uiChatIconNames = <String>[
  'accountCircle',
  'add',
  'arrowBack',
  'arrowForward',
  'attachFile',
  'calendarToday',
  'call',
  'camera',
  'check',
  'close',
  'delete',
  'download',
  'edit',
  'error',
  'event',
  'favorite',
  'favoriteOff',
  'folder',
  'help',
  'home',
  'info',
  'locationOn',
  'lock',
  'lockOpen',
  'mail',
  'menu',
  'moreHoriz',
  'moreVert',
  'notifications',
  'notificationsOff',
  'payment',
  'person',
  'phone',
  'photo',
  'print',
  'refresh',
  'search',
  'send',
  'settings',
  'share',
  'shoppingCart',
  'star',
  'starHalf',
  'starOff',
  'upload',
  'visibility',
  'visibilityOff',
  'warning',
  'dashboard',
  'checkCircle',
  'schedule',
  'radioButtonUnchecked',
  'trendingUp',
  'groups',
  'timer',
  'bugReport',
  'speed',
  'pending',
  'merge',
  'rocketLaunch',
  'comment',
];

const Map<String, Object?> _a2uiIdSchema = {'type': 'string'};
const Map<String, Object?> _a2uiComponentSchema = {'type': 'string'};
const Map<String, Object?> _a2uiStringSchema = {'type': 'string'};
const Map<String, Object?> _a2uiNumberSchema = {'type': 'number'};
const Map<String, Object?> _a2uiIntegerSchema = {'type': 'integer'};
const Map<String, Object?> _a2uiReferenceSchema = {
  'type': 'object',
  'required': ['path'],
  'properties': {'path': _a2uiStringSchema},
};
const Map<String, Object?> _a2uiStringValueSchema = {
  'oneOf': [_a2uiStringSchema, _a2uiReferenceSchema],
};
const Map<String, Object?> _a2uiNumberValueSchema = {
  'oneOf': [_a2uiNumberSchema, _a2uiReferenceSchema],
};
const Map<String, Object?> _a2uiBooleanValueSchema = {
  'oneOf': [
    {'type': 'boolean'},
    _a2uiReferenceSchema,
  ],
};
const Map<String, Object?> _a2uiChoiceValueSchema = {
  'oneOf': [
    _a2uiStringSchema,
    {'type': 'array', 'items': _a2uiStringSchema},
    _a2uiReferenceSchema,
  ],
};
const Map<String, Object?> _a2uiChildrenSchema = {
  'oneOf': [
    {'type': 'array', 'items': _a2uiStringSchema},
    {
      'type': 'object',
      'required': ['path', 'componentId'],
      'properties': {
        'path': _a2uiStringSchema,
        'componentId': _a2uiStringSchema,
      },
    },
  ],
};
const Map<String, Object?> _a2uiChoiceOptionSchema = {
  'type': 'object',
  'required': ['value', 'label'],
  'properties': {
    'value': _a2uiStringSchema,
    'label': _a2uiStringSchema,
    'disabled': {'type': 'boolean'},
  },
};
const Map<String, Object?> _a2uiTabSchema = {
  'type': 'object',
  'required': ['label', 'content'],
  'properties': {'label': _a2uiStringValueSchema, 'content': _a2uiStringSchema},
};
const Map<String, Object?> _a2uiFieldProperties = {
  'required': {'type': 'boolean'},
  'disabled': {'type': 'boolean'},
  'readOnly': {'type': 'boolean'},
  'placeholder': _a2uiStringSchema,
  'helperText': _a2uiStringSchema,
  'errorText': _a2uiStringSchema,
};
const Map<String, Object?> _a2uiToneSchema = {
  'type': 'string',
  'enum': ['primary', 'secondary', 'success', 'warning', 'error', 'info'],
};
const Map<String, Object?> _a2uiGapSchema = {
  'type': 'string',
  'enum': ['none', 'xs', 'sm', 'md', 'lg', 'xl'],
};
const Map<String, Object?> _a2uiScalarSchema = {
  'oneOf': [
    {'type': 'string'},
    {'type': 'number'},
    {'type': 'boolean'},
    {'type': 'null'},
  ],
};
const Map<String, Object?> _a2uiTableColumnSchema = {
  'type': 'object',
  'required': ['label'],
  'properties': {
    'label': _a2uiStringSchema,
    'align': {
      'type': 'string',
      'enum': ['start', 'center', 'end'],
    },
    'type': {
      'type': 'string',
      'enum': ['text', 'number', 'boolean'],
    },
    'format': {
      'type': 'string',
      'enum': ['plain', 'number', 'percent'],
    },
    'sortable': {'type': 'boolean'},
  },
};
const Map<String, Object?> _a2uiTableRowSchema = {
  'type': 'object',
  'required': ['cells'],
  'properties': {
    'cells': {'type': 'array', 'items': _a2uiScalarSchema},
    'tone': _a2uiToneSchema,
  },
};
const Map<String, Object?> _a2uiBaseProperties = {
  'id': _a2uiIdSchema,
  'component': _a2uiComponentSchema,
};

const a2uiChatComponentSchemas = <String, Map<String, Object?>>{
  'Progress': {
    'type': 'object',
    'required': ['id', 'component'],
    'properties': {
      ..._a2uiBaseProperties,
      'value': {
        'oneOf': [
          {'type': 'number', 'minimum': 0, 'maximum': 1},
          {
            'type': 'object',
            'required': ['path'],
            'properties': {
              'path': {'type': 'string', 'pattern': '^/'},
            },
          },
        ],
      },
      'label': {
        'oneOf': [
          {'type': 'string'},
          {
            'type': 'object',
            'required': ['path'],
            'properties': {
              'path': {'type': 'string', 'pattern': '^/'},
            },
          },
        ],
      },
      'tone': {
        'type': 'string',
        'enum': ['primary', 'secondary', 'success', 'warning', 'error', 'info'],
      },
      'indeterminate': {'type': 'boolean'},
      'showValue': {'type': 'boolean'},
    },
  },
  'Badge': {
    'type': 'object',
    'required': ['id', 'component', 'label'],
    'properties': {
      ..._a2uiBaseProperties,
      'label': {
        'oneOf': [
          {'type': 'string'},
          {
            'type': 'object',
            'required': ['path'],
            'properties': {
              'path': {'type': 'string', 'pattern': '^/'},
            },
          },
        ],
      },
      'size': {
        'type': 'string',
        'enum': ['small', 'medium', 'large'],
      },
      'tone': {
        'type': 'string',
        'enum': ['primary', 'secondary', 'success', 'warning', 'error', 'info'],
      },
    },
  },
  'Avatar': {
    'type': 'object',
    'required': ['id', 'component', 'name'],
    'properties': {
      ..._a2uiBaseProperties,
      'name': {
        'oneOf': [
          {'type': 'string'},
          {
            'type': 'object',
            'required': ['path'],
            'properties': {
              'path': {'type': 'string', 'pattern': '^/'},
            },
          },
        ],
      },
      'size': {
        'type': 'string',
        'enum': ['small', 'medium', 'large'],
      },
      'url': {
        'oneOf': [
          {'type': 'string'},
          {
            'type': 'object',
            'required': ['path'],
            'properties': {
              'path': {'type': 'string', 'pattern': '^/'},
            },
          },
        ],
      },
    },
  },
  'AvatarGroup': {
    'type': 'object',
    'required': ['id', 'component', 'avatars'],
    'properties': {
      ..._a2uiBaseProperties,
      'avatars': {
        'oneOf': [
          {
            'type': 'array',
            'items': {
              'type': 'object',
              'required': ['name'],
              'properties': {
                'name': {'type': 'string'},
                'url': {'type': 'string'},
              },
            },
          },
          {
            'type': 'object',
            'required': ['path'],
            'properties': {
              'path': {'type': 'string', 'pattern': '^/'},
            },
          },
        ],
      },
      'maxVisible': {'type': 'integer', 'minimum': 1, 'maximum': 20},
    },
  },
  'Table': {
    'type': 'object',
    'required': ['id', 'component', 'columns', 'rows'],
    'properties': {
      ..._a2uiBaseProperties,
      'columns': {
        'oneOf': [
          {
            'type': 'array',
            'items': {
              'oneOf': [_a2uiStringValueSchema, _a2uiTableColumnSchema],
            },
            'minItems': 1,
          },
          {
            'type': 'object',
            'required': ['path'],
            'properties': {
              'path': {'type': 'string', 'pattern': '^/'},
            },
          },
        ],
      },
      'rows': {
        'oneOf': [
          {
            'type': 'array',
            'items': {
              'oneOf': [
                {'type': 'array', 'items': _a2uiScalarSchema},
                _a2uiTableRowSchema,
              ],
            },
          },
          {
            'type': 'object',
            'required': ['path'],
            'properties': {
              'path': {'type': 'string', 'pattern': '^/'},
            },
          },
        ],
      },
      'caption': {
        'oneOf': [
          {'type': 'string'},
          {
            'type': 'object',
            'required': ['path'],
            'properties': {
              'path': {'type': 'string', 'pattern': '^/'},
            },
          },
        ],
      },
      'emptyText': _a2uiStringValueSchema,
      'noValueLabel': _a2uiStringValueSchema,
    },
  },
  'Chart': {
    'type': 'object',
    'required': ['id', 'component', 'labels', 'series'],
    'properties': {
      ..._a2uiBaseProperties,
      'labels': {
        'oneOf': [
          {
            'type': 'array',
            'items': {'type': 'string'},
            'minItems': 1,
          },
          {
            'type': 'object',
            'required': ['path'],
            'properties': {
              'path': {'type': 'string', 'pattern': '^/'},
            },
          },
        ],
      },
      'series': {
        'oneOf': [
          {
            'type': 'array',
            'items': {
              'type': 'object',
              'required': ['label', 'values'],
              'properties': {
                'label': {'type': 'string'},
                'values': {
                  'type': 'array',
                  'items': {'type': 'number'},
                },
                'tone': {
                  'type': 'string',
                  'enum': [
                    'primary',
                    'secondary',
                    'success',
                    'warning',
                    'error',
                    'info',
                  ],
                },
              },
            },
            'minItems': 1,
          },
          {
            'type': 'object',
            'required': ['path'],
            'properties': {
              'path': {'type': 'string', 'pattern': '^/'},
            },
          },
        ],
      },
      'variant': {
        'type': 'string',
        'enum': ['line', 'bar', 'pie', 'donut'],
      },
      'label': {
        'oneOf': [
          {'type': 'string'},
          {
            'type': 'object',
            'required': ['path'],
            'properties': {
              'path': {'type': 'string', 'pattern': '^/'},
            },
          },
        ],
      },
      'stacked': {'type': 'boolean'},
      'minY': _a2uiNumberSchema,
      'maxY': _a2uiNumberSchema,
      'xAxisTitle': _a2uiStringValueSchema,
      'yAxisTitle': _a2uiStringValueSchema,
      'unit': _a2uiStringValueSchema,
      'numberFormat': {
        'type': 'string',
        'enum': ['decimal', 'percent'],
      },
      'palette': {'type': 'array', 'minItems': 1, 'items': _a2uiToneSchema},
    },
  },
  'EmptyState': {
    'type': 'object',
    'required': ['id', 'component', 'title'],
    'properties': {
      ..._a2uiBaseProperties,
      'title': {
        'oneOf': [
          {'type': 'string'},
          {
            'type': 'object',
            'required': ['path'],
            'properties': {
              'path': {'type': 'string', 'pattern': '^/'},
            },
          },
        ],
      },
      'description': {
        'oneOf': [
          {'type': 'string'},
          {
            'type': 'object',
            'required': ['path'],
            'properties': {
              'path': {'type': 'string', 'pattern': '^/'},
            },
          },
        ],
      },
      'icon': {'type': 'string', 'enum': a2uiChatIconNames},
    },
  },
  'LoadingIndicator': {
    'type': 'object',
    'required': ['id', 'component', 'label'],
    'properties': {
      ..._a2uiBaseProperties,
      'label': {
        'oneOf': [
          {'type': 'string'},
          {
            'type': 'object',
            'required': ['path'],
            'properties': {
              'path': {'type': 'string', 'pattern': '^/'},
            },
          },
        ],
      },
      'size': {
        'type': 'string',
        'enum': ['small', 'medium', 'large'],
      },
      'inline': {'type': 'boolean'},
      'value': {
        'oneOf': [
          {'type': 'number', 'minimum': 0, 'maximum': 1},
          _a2uiReferenceSchema,
        ],
      },
    },
  },
  'AnimatedContent': {
    'type': 'object',
    'required': ['id', 'component', 'child'],
    'properties': {
      ..._a2uiBaseProperties,
      'child': {'type': 'string', 'minLength': 1},
      'transition': {
        'type': 'string',
        'enum': ['none', 'fade', 'slide', 'scale'],
      },
      'trigger': {
        'type': 'string',
        'enum': ['mount', 'keyChange'],
      },
    },
  },
  'Button': {
    'type': 'object',
    'required': ['id', 'component'],
    'properties': {
      ..._a2uiBaseProperties,
      'child': _a2uiStringSchema,
      'label': _a2uiStringValueSchema,
      'icon': {'type': 'string', 'enum': a2uiChatIconNames},
      'disabled': {'type': 'boolean'},
      'href': {'type': 'string', 'pattern': '^https://'},
      'variant': {
        'type': 'string',
        'enum': ['primary', 'outlined', 'text'],
      },
    },
  },
  'Card': {
    'type': 'object',
    'required': ['id', 'component', 'child'],
    'properties': {
      ..._a2uiBaseProperties,
      'child': _a2uiStringSchema,
      'title': _a2uiStringSchema,
      'subtitle': _a2uiStringSchema,
      'tone': {
        'type': 'string',
        'enum': ['primary', 'secondary', 'success', 'warning', 'error', 'info'],
      },
      'style': {
        'type': 'string',
        'enum': ['elevated', 'outlined'],
      },
    },
  },
  'CheckBox': {
    'type': 'object',
    'required': ['id', 'component', 'label', 'value'],
    'properties': {
      ..._a2uiBaseProperties,
      'label': _a2uiStringValueSchema,
      'value': _a2uiBooleanValueSchema,
      ..._a2uiFieldProperties,
    },
  },
  'ChoicePicker': {
    'type': 'object',
    'required': ['id', 'component', 'options', 'value'],
    'properties': {
      ..._a2uiBaseProperties,
      'label': _a2uiStringValueSchema,
      'options': {'type': 'array', 'items': _a2uiChoiceOptionSchema},
      'value': _a2uiChoiceValueSchema,
      'variant': {
        'type': 'string',
        'enum': ['single', 'multiple'],
      },
      'presentation': {
        'type': 'string',
        'enum': ['list', 'chips'],
      },
      'maxSelections': {'type': 'integer', 'minimum': 1},
      'minSelections': {'type': 'integer', 'minimum': 0},
      ..._a2uiFieldProperties,
    },
  },
  'Column': {
    'type': 'object',
    'required': ['id', 'component', 'children'],
    'properties': {
      ..._a2uiBaseProperties,
      'children': _a2uiChildrenSchema,
      'justify': {
        'type': 'string',
        'enum': [
          'start',
          'center',
          'end',
          'spaceBetween',
          'spaceAround',
          'spaceEvenly',
        ],
      },
      'align': {
        'type': 'string',
        'enum': ['start', 'center', 'end', 'stretch'],
      },
      'gap': {
        'type': 'string',
        'enum': ['none', 'xs', 'sm', 'md', 'lg', 'xl'],
      },
    },
  },
  'DateTimeInput': {
    'type': 'object',
    'required': ['id', 'component', 'value'],
    'properties': {
      ..._a2uiBaseProperties,
      'variant': {
        'type': 'string',
        'enum': ['date', 'time', 'dateTime'],
      },
      'value': {
        ..._a2uiStringValueSchema,
        'description':
            'Use YYYY-MM-DD for date, HH:mm for time, and RFC3339 with an '
            'explicit offset or Z for dateTime.',
      },
      'label': _a2uiStringValueSchema,
      'min': _a2uiStringSchema,
      'max': _a2uiStringSchema,
      ..._a2uiFieldProperties,
    },
  },
  'Divider': {
    'type': 'object',
    'required': ['id', 'component'],
    'properties': {
      ..._a2uiBaseProperties,
      'axis': {
        'type': 'string',
        'enum': ['horizontal', 'vertical'],
      },
    },
  },
  'Icon': {
    'type': 'object',
    'required': ['id', 'component', 'name'],
    'properties': {
      ..._a2uiBaseProperties,
      'name': {'type': 'string', 'enum': a2uiChatIconNames},
      'label': _a2uiStringValueSchema,
      'size': {
        'type': 'string',
        'enum': ['small', 'medium', 'large', 'extraLarge'],
      },
      'tone': {
        'type': 'string',
        'enum': ['primary', 'secondary', 'success', 'warning', 'error', 'info'],
      },
    },
  },
  'Image': {
    'type': 'object',
    'required': ['id', 'component', 'url'],
    'properties': {
      ..._a2uiBaseProperties,
      'url': _a2uiStringSchema,
      'fit': {
        'type': 'string',
        'enum': ['contain', 'cover', 'fill', 'fitWidth', 'fitHeight'],
      },
      'variant': {
        'type': 'string',
        'enum': ['normal', 'circle', 'avatar'],
      },
      'label': _a2uiStringValueSchema,
      'width': {'type': 'number', 'minimum': 1, 'maximum': 1024},
      'height': {'type': 'number', 'minimum': 1, 'maximum': 1024},
      'fallbackText': _a2uiStringValueSchema,
      'fallbackIcon': {'type': 'string', 'enum': a2uiChatIconNames},
    },
  },
  'List': {
    'type': 'object',
    'required': ['id', 'component', 'children'],
    'properties': {
      ..._a2uiBaseProperties,
      'children': _a2uiChildrenSchema,
      'direction': {
        'type': 'string',
        'enum': ['vertical', 'horizontal'],
      },
      'align': {
        'type': 'string',
        'enum': ['start', 'center', 'end', 'stretch'],
      },
      'gap': {
        'type': 'string',
        'enum': ['none', 'xs', 'sm', 'md', 'lg', 'xl'],
      },
    },
  },
  'Modal': {
    'type': 'object',
    'required': ['id', 'component', 'trigger', 'content'],
    'properties': {
      ..._a2uiBaseProperties,
      'trigger': _a2uiStringSchema,
      'content': _a2uiStringSchema,
      'title': _a2uiStringValueSchema,
      'size': {
        'type': 'string',
        'enum': ['small', 'medium', 'large'],
      },
      'closeLabel': _a2uiStringValueSchema,
    },
  },
  'Row': {
    'type': 'object',
    'required': ['id', 'component', 'children'],
    'properties': {
      ..._a2uiBaseProperties,
      'children': _a2uiChildrenSchema,
      'justify': {
        'type': 'string',
        'enum': [
          'start',
          'center',
          'end',
          'spaceBetween',
          'spaceAround',
          'spaceEvenly',
        ],
      },
      'align': {
        'type': 'string',
        'enum': ['start', 'center', 'end', 'stretch'],
      },
      'gap': {
        'type': 'string',
        'enum': ['none', 'xs', 'sm', 'md', 'lg', 'xl'],
      },
    },
  },
  'Slider': {
    'type': 'object',
    'required': ['id', 'component', 'value', 'min', 'max'],
    'properties': {
      ..._a2uiBaseProperties,
      'label': _a2uiStringValueSchema,
      'value': _a2uiNumberValueSchema,
      'min': _a2uiNumberSchema,
      'max': _a2uiNumberSchema,
      'step': _a2uiNumberSchema,
      'precision': _a2uiIntegerSchema,
      'unit': _a2uiStringSchema,
      'showValue': {'type': 'boolean'},
      'valueFormat': {
        'type': 'string',
        'enum': ['decimal', 'percent'],
      },
      'marks': {
        'type': 'array',
        'items': {
          'type': 'object',
          'required': ['value'],
          'properties': {
            'value': _a2uiNumberSchema,
            'label': _a2uiStringSchema,
          },
        },
      },
      ..._a2uiFieldProperties,
    },
  },
  'Tabs': {
    'type': 'object',
    'required': ['id', 'component', 'tabs'],
    'properties': {
      ..._a2uiBaseProperties,
      'tabs': {
        'oneOf': [
          {'type': 'array', 'items': _a2uiTabSchema, 'minItems': 1},
          {
            'type': 'object',
            'required': ['path', 'componentId'],
            'properties': {
              'path': _a2uiStringSchema,
              'componentId': _a2uiStringSchema,
            },
          },
        ],
      },
      'activeTab': _a2uiNumberValueSchema,
    },
  },
  'Text': {
    'type': 'object',
    'required': ['id', 'component', 'text'],
    'properties': {
      ..._a2uiBaseProperties,
      'text': _a2uiStringValueSchema,
      'variant': {
        'type': 'string',
        'enum': ['h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'body', 'caption'],
      },
      'tone': {
        'type': 'string',
        'enum': ['primary', 'secondary', 'success', 'warning', 'error', 'info'],
      },
      'align': {
        'type': 'string',
        'enum': ['start', 'center', 'end', 'justify'],
      },
      'maxLines': {'type': 'integer', 'minimum': 1, 'maximum': 20},
      'truncation': {
        'type': 'string',
        'enum': ['none', 'ellipsis'],
      },
    },
  },
  'TextField': {
    'type': 'object',
    'required': ['id', 'component', 'value'],
    'properties': {
      ..._a2uiBaseProperties,
      'label': _a2uiStringValueSchema,
      'value': _a2uiStringValueSchema,
      'variant': {
        'type': 'string',
        'enum': ['text', 'number', 'email', 'password', 'multiline'],
      },
      'minLength': {'type': 'integer', 'minimum': 0},
      'maxLength': {'type': 'integer', 'minimum': 1},
      'pattern': _a2uiStringSchema,
      ..._a2uiFieldProperties,
    },
  },
  'Tab': {
    'type': 'object',
    'required': ['id', 'component', 'label', 'content'],
    'properties': {
      ..._a2uiBaseProperties,
      'label': _a2uiStringValueSchema,
      'content': _a2uiStringSchema,
    },
  },
  'Form': {
    'type': 'object',
    'required': ['id', 'component', 'child'],
    'properties': {
      ..._a2uiBaseProperties,
      'child': _a2uiStringSchema,
      'submitLabel': _a2uiStringSchema,
      'resetLabel': _a2uiStringSchema,
    },
  },
  'Fieldset': {
    'type': 'object',
    'required': ['id', 'component', 'legend', 'child'],
    'properties': {
      ..._a2uiBaseProperties,
      'legend': _a2uiStringSchema,
      'description': _a2uiStringSchema,
      'child': _a2uiStringSchema,
    },
  },
  'Alert': {
    'type': 'object',
    'required': ['id', 'component', 'title'],
    'properties': {
      ..._a2uiBaseProperties,
      'title': _a2uiStringSchema,
      'description': _a2uiStringSchema,
      'icon': {'type': 'string', 'enum': a2uiChatIconNames},
      'tone': _a2uiToneSchema,
    },
  },
  'Stat': {
    'type': 'object',
    'required': ['id', 'component', 'value', 'label'],
    'properties': {
      ..._a2uiBaseProperties,
      'value': _a2uiStringSchema,
      'label': _a2uiStringSchema,
      'delta': _a2uiStringSchema,
      'icon': {'type': 'string', 'enum': a2uiChatIconNames},
      'tone': _a2uiToneSchema,
    },
  },
  'Link': {
    'type': 'object',
    'required': ['id', 'component', 'label', 'href'],
    'properties': {
      ..._a2uiBaseProperties,
      'label': _a2uiStringSchema,
      'href': {'type': 'string', 'pattern': '^https://'},
      'semanticLabel': _a2uiStringSchema,
    },
  },
  'Tooltip': {
    'type': 'object',
    'required': ['id', 'component', 'message', 'child'],
    'properties': {
      ..._a2uiBaseProperties,
      'message': _a2uiStringSchema,
      'child': _a2uiStringSchema,
    },
  },
  'Accordion': {
    'type': 'object',
    'required': ['id', 'component', 'items'],
    'properties': {
      ..._a2uiBaseProperties,
      'items': {
        'type': 'array',
        'minItems': 1,
        'items': {
          'type': 'object',
          'required': ['title', 'content'],
          'properties': {
            'title': _a2uiStringSchema,
            'content': _a2uiStringSchema,
          },
        },
      },
      'expanded': {'type': 'array', 'items': _a2uiIntegerSchema},
    },
  },
  'Stepper': {
    'type': 'object',
    'required': ['id', 'component', 'steps'],
    'properties': {
      ..._a2uiBaseProperties,
      'steps': {
        'type': 'array',
        'minItems': 1,
        'items': {
          'type': 'object',
          'required': ['title'],
          'properties': {
            'title': _a2uiStringSchema,
            'description': _a2uiStringSchema,
            'state': {
              'type': 'string',
              'enum': ['pending', 'current', 'complete', 'error'],
            },
          },
        },
      },
    },
  },
  'Timeline': {
    'type': 'object',
    'required': ['id', 'component', 'entries'],
    'properties': {
      ..._a2uiBaseProperties,
      'entries': {
        'type': 'array',
        'minItems': 1,
        'items': {
          'type': 'object',
          'required': ['title'],
          'properties': {
            'title': _a2uiStringSchema,
            'description': _a2uiStringSchema,
            'time': _a2uiStringSchema,
            'tone': _a2uiToneSchema,
          },
        },
      },
    },
  },
  'Skeleton': {
    'type': 'object',
    'required': ['id', 'component'],
    'properties': {
      ..._a2uiBaseProperties,
      'width': {'type': 'number', 'minimum': 1, 'maximum': 4096},
      'height': {'type': 'number', 'minimum': 1, 'maximum': 4096},
      'shape': {
        'type': 'string',
        'enum': ['rectangle', 'circle'],
      },
      'label': _a2uiStringSchema,
    },
  },
  'Grid': {
    'type': 'object',
    'required': ['id', 'component', 'children'],
    'properties': {
      ..._a2uiBaseProperties,
      'children': _a2uiChildrenSchema,
      'minimumItemWidth': {'type': 'number', 'minimum': 80, 'maximum': 1200},
      'gap': _a2uiGapSchema,
    },
  },
  'Wrap': {
    'type': 'object',
    'required': ['id', 'component', 'children'],
    'properties': {
      ..._a2uiBaseProperties,
      'children': _a2uiChildrenSchema,
      'gap': _a2uiGapSchema,
    },
  },
  'Spacer': {
    'type': 'object',
    'required': ['id', 'component'],
    'properties': {
      ..._a2uiBaseProperties,
      'size': {'type': 'number', 'minimum': 0, 'maximum': 1024},
      'flex': {'type': 'integer', 'minimum': 1, 'maximum': 12},
    },
  },
  'FlexItem': {
    'type': 'object',
    'required': ['id', 'component', 'child'],
    'properties': {
      ..._a2uiBaseProperties,
      'child': _a2uiStringSchema,
      'flex': {'type': 'integer', 'minimum': 1, 'maximum': 12},
      'fit': {
        'type': 'string',
        'enum': ['loose', 'tight'],
      },
    },
  },
  'Rating': {
    'type': 'object',
    'required': ['id', 'component', 'value'],
    'properties': {
      ..._a2uiBaseProperties,
      'value': _a2uiNumberValueSchema,
      'max': {'type': 'integer', 'minimum': 1, 'maximum': 10},
      'label': _a2uiStringSchema,
      ..._a2uiFieldProperties,
    },
  },
  'TagInput': {
    'type': 'object',
    'required': ['id', 'component', 'value'],
    'properties': {
      ..._a2uiBaseProperties,
      'value': {
        'oneOf': [
          {'type': 'array', 'items': _a2uiStringSchema},
          _a2uiReferenceSchema,
        ],
      },
      'label': _a2uiStringSchema,
      'maxSelections': {'type': 'integer', 'minimum': 1, 'maximum': 100},
      ..._a2uiFieldProperties,
    },
  },
  'CodeBlock': {
    'type': 'object',
    'required': ['id', 'component', 'code'],
    'properties': {
      ..._a2uiBaseProperties,
      'code': _a2uiStringSchema,
      'language': _a2uiStringSchema,
      'label': _a2uiStringSchema,
    },
  },
  'KeyValue': {
    'type': 'object',
    'required': ['id', 'component', 'entries'],
    'properties': {
      ..._a2uiBaseProperties,
      'entries': {
        'type': 'array',
        'minItems': 1,
        'items': {
          'type': 'object',
          'required': ['label', 'value'],
          'properties': {
            'label': _a2uiStringSchema,
            'value': _a2uiStringSchema,
          },
        },
      },
    },
  },
  'Section': {
    'type': 'object',
    'required': ['id', 'component', 'title', 'child'],
    'properties': {
      ..._a2uiBaseProperties,
      'title': _a2uiStringSchema,
      'description': _a2uiStringSchema,
      'child': _a2uiStringSchema,
    },
  },
};

const a2uiChatComponentExamples = <String, Map<String, Object?>>{
  'Progress': {
    'id': 'progress',
    'component': 'Progress',
    'value': 0.75,
    'label': 'Progress',
    'tone': 'primary',
  },
  'Badge': {
    'id': 'badge',
    'component': 'Badge',
    'label': 'Ready',
    'tone': 'success',
  },
  'Avatar': {'id': 'avatar', 'component': 'Avatar', 'name': 'Ada'},
  'AvatarGroup': {
    'id': 'avatargroup',
    'component': 'AvatarGroup',
    'avatars': [
      {'name': 'Ada'},
      {'name': 'Grace'},
    ],
    'maxVisible': 5,
  },
  'Table': {
    'id': 'table',
    'component': 'Table',
    'columns': ['Name', 'Count'],
    'rows': [
      ['Ada', 3],
      ['Grace', 5],
    ],
  },
  'Chart': {
    'id': 'chart',
    'component': 'Chart',
    'labels': ['Mon', 'Tue'],
    'series': [
      {
        'label': 'Completed',
        'values': [3, 5],
      },
    ],
    'variant': 'bar',
  },
  'EmptyState': {
    'id': 'emptystate',
    'component': 'EmptyState',
    'title': 'No results',
    'description': 'Try another search.',
    'icon': 'search',
  },
  'LoadingIndicator': {
    'id': 'loadingindicator',
    'component': 'LoadingIndicator',
    'label': 'Loading',
  },
  'AnimatedContent': {
    'id': 'animatedcontent',
    'component': 'AnimatedContent',
    'child': 'content',
    'transition': 'fade',
  },
  'Button': {'id': 'submit', 'component': 'Button', 'child': 'submit-label'},
  'Card': {'id': 'card', 'component': 'Card', 'child': 'content'},
  'CheckBox': {
    'id': 'done',
    'component': 'CheckBox',
    'label': 'Done',
    'value': {'path': '/done'},
  },
  'ChoicePicker': {
    'id': 'choice',
    'component': 'ChoicePicker',
    'label': 'Choose one',
    'options': [
      {'value': 'a', 'label': 'A'},
      {'value': 'b', 'label': 'B'},
    ],
    'value': {'path': '/choice'},
  },
  'Column': {
    'id': 'root',
    'component': 'Column',
    'children': ['title', 'submit'],
  },
  'DateTimeInput': {
    'id': 'date',
    'component': 'DateTimeInput',
    'variant': 'date',
    'value': {'path': '/date'},
  },
  'Divider': {'id': 'divider', 'component': 'Divider'},
  'Icon': {'id': 'info', 'component': 'Icon', 'name': 'info'},
  'Image': {
    'id': 'photo',
    'component': 'Image',
    'url': 'https://example.com/photo.png',
  },
  'List': {
    'id': 'items',
    'component': 'List',
    'children': ['item-1', 'item-2'],
  },
  'Modal': {
    'id': 'details',
    'component': 'Modal',
    'trigger': 'open',
    'content': 'details-content',
  },
  'Row': {
    'id': 'actions',
    'component': 'Row',
    'children': ['back', 'next'],
  },
  'Slider': {
    'id': 'amount',
    'component': 'Slider',
    'label': 'Amount',
    'value': {'path': '/amount'},
    'min': 0,
    'max': 100,
    'step': 1,
    'precision': 2,
  },
  'Tabs': {
    'id': 'tabs',
    'component': 'Tabs',
    'tabs': [
      {'label': 'One', 'content': 'one-content'},
      {'label': 'Two', 'content': 'two-content'},
    ],
    'activeTab': {'path': '/activeTab'},
  },
  'Text': {'id': 'title', 'component': 'Text', 'text': 'Hello'},
  'TextField': {
    'id': 'name',
    'component': 'TextField',
    'label': 'Name',
    'value': {'path': '/name'},
  },
  'Tab': {
    'id': 'tab-template',
    'component': 'Tab',
    'label': 'Template tab',
    'content': 'tab-content',
  },
  'Form': {'id': 'form', 'component': 'Form', 'child': 'form-content'},
  'Fieldset': {
    'id': 'fieldset',
    'component': 'Fieldset',
    'legend': 'Details',
    'child': 'field-content',
  },
  'Alert': {
    'id': 'alert',
    'component': 'Alert',
    'title': 'Heads up',
    'description': 'This is an informational alert.',
    'tone': 'info',
  },
  'Stat': {
    'id': 'stat',
    'component': 'Stat',
    'value': '42',
    'label': 'Open items',
    'tone': 'primary',
  },
  'Link': {
    'id': 'link',
    'component': 'Link',
    'label': 'Read more',
    'href': 'https://example.com',
  },
  'Tooltip': {
    'id': 'tooltip',
    'component': 'Tooltip',
    'message': 'More information',
    'child': 'tooltip-child',
  },
  'Accordion': {
    'id': 'accordion',
    'component': 'Accordion',
    'items': [
      {'title': 'Details', 'content': 'accordion-content'},
    ],
  },
  'Stepper': {
    'id': 'stepper',
    'component': 'Stepper',
    'steps': [
      {'title': 'Started', 'state': 'complete'},
      {'title': 'Review', 'state': 'current'},
    ],
  },
  'Timeline': {
    'id': 'timeline',
    'component': 'Timeline',
    'entries': [
      {'title': 'Created', 'time': 'Today'},
    ],
  },
  'Skeleton': {'id': 'skeleton', 'component': 'Skeleton', 'height': 24},
  'Grid': {
    'id': 'grid',
    'component': 'Grid',
    'children': ['grid-child'],
  },
  'Wrap': {
    'id': 'wrap',
    'component': 'Wrap',
    'children': ['wrap-child'],
  },
  'Spacer': {'id': 'spacer', 'component': 'Spacer', 'size': 16},
  'FlexItem': {
    'id': 'flex-item',
    'component': 'FlexItem',
    'child': 'flex-child',
  },
  'Rating': {
    'id': 'rating',
    'component': 'Rating',
    'value': {'path': '/rating'},
    'max': 5,
  },
  'TagInput': {
    'id': 'tags',
    'component': 'TagInput',
    'value': {'path': '/tags'},
  },
  'CodeBlock': {
    'id': 'code',
    'component': 'CodeBlock',
    'code': 'print("Hello")',
    'language': 'dart',
  },
  'KeyValue': {
    'id': 'key-value',
    'component': 'KeyValue',
    'entries': [
      {'label': 'Status', 'value': 'Ready'},
    ],
  },
  'Section': {
    'id': 'section',
    'component': 'Section',
    'title': 'Summary',
    'child': 'section-content',
  },
};
