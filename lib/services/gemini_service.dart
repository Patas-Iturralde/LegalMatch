import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static const String _apiKey = 'AIzaSyCqOoy37xN3R_VCHOpwn2lmesPbR2oXwyE'; // Reemplaza con tu API key
  late final GenerativeModel _model;
  
  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.8,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 2048,
      ),
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium),
      ],
    );
  }

  // ========== VALIDACIÓN DE CONSULTAS LEGALES ==========
  
  Future<bool> isValidLegalQuery(String userMessage) async {
    try {
      final prompt = '''
Analiza si el siguiente mensaje es una consulta legal válida:

"$userMessage"

CRITERIOS PARA SER CONSULTA LEGAL VÁLIDA:
✅ VÁLIDO:
- Problemas legales específicos (contratos, demandas, derechos)
- Situaciones que requieren asesoría jurídica
- Preguntas sobre leyes, procedimientos legales
- Casos de derecho (civil, penal, laboral, familiar, etc.)
- Consultas sobre derechos y obligaciones
- Problemas con empresas, trabajo, familia, propiedades
- Accidentes, negligencia médica, disputas

❌ NO VÁLIDO:
- Saludos simples sin contenido legal ("hola", "buenos días")
- Preguntas sobre otros temas (medicina, tecnología, cocina)
- Solicitudes vagas sin contexto ("dame un resumen", "ayúdame")
- Conversación casual sin componente jurídico
- Mensajes muy cortos o incoherentes
- Preguntas sobre el funcionamiento del chatbot

¿Es una consulta legal válida? Responde SOLO: SÍ o NO
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      final result = response.text?.trim().toUpperCase();
      return result == 'SÍ' || result == 'SI' || result == 'YES';
    } catch (e) {
      print('Error al validar consulta legal: $e');
      return _isValidLegalQueryByKeywords(userMessage);
    }
  }

  // ========== RESPUESTA PRINCIPAL DE IA ==========
  
  Future<String> getLegalAdvice(String userMessage) async {
    try {
      // Validar si es una consulta legal válida
      final isValid = await isValidLegalQuery(userMessage);
      
      if (!isValid) {
        return _getInvalidQueryResponse();
      }

      final prompt = '''
Eres un asistente legal especializado en derecho ecuatoriano. Analiza esta consulta y proporciona una respuesta útil y específica:

CONSULTA: "$userMessage"

INSTRUCCIONES OBLIGATORIAS:
1. Identifica el área legal específica del problema
2. Analiza la situación legal planteada
3. Proporciona pasos concretos y accionables
4. Menciona documentos específicos necesarios
5. Indica nivel de urgencia y razones
6. Usa terminología legal clara pero accesible
7. Máximo 300 palabras

ESTRUCTURA OBLIGATORIA:
🏛️ **Área Legal:** [Especialidad jurídica específica]

📋 **Análisis Legal:** [Análisis específico del problema planteado]

⚡ **Acciones Inmediatas:**
• [Paso específico 1]
• [Paso específico 2]
• [Paso específico 3]

📄 **Documentos Necesarios:**
• [Documento específico 1]
• [Documento específico 2]
• [Documento específico 3]

⚠️ **Nivel de Urgencia:** [Alto/Medio/Bajo] - [Razón específica]

🎯 **Recomendación:** [Consejo final específico]

IMPORTANTE: 
- NO uses respuestas genéricas
- SÉ ESPECÍFICO al problema planteado
- Proporciona información PRÁCTICA
- Considera el contexto ecuatoriano
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      if (response.text != null && response.text!.length > 100) {
        return response.text!;
      } else {
        return _getSpecificLegalResponse(userMessage);
      }
    } catch (e) {
      print('Error al obtener respuesta de Gemini: $e');
      return _getSpecificLegalResponse(userMessage);
    }
  }

  // ========== CLASIFICACIÓN DE ESPECIALIDADES ==========
  
  Future<String> classifyLegalSpecialty(String userMessage) async {
    try {
      // Verificar si es una consulta legal válida
      final isValid = await isValidLegalQuery(userMessage);
      
      if (!isValid) {
        return 'Consulta No Válida';
      }

      final prompt = '''
Clasifica esta consulta legal en UNA especialidad específica:

"$userMessage"

ESPECIALIDADES DISPONIBLES:
- Derecho Civil (contratos, propiedad, responsabilidad civil, negligencia)
- Derecho Penal (delitos, denuncias, procesos penales)
- Derecho Laboral (trabajo, despidos, derechos laborales)
- Derecho Familiar (divorcio, custodia, alimentos, matrimonio)
- Derecho Comercial (empresas, sociedades, contratos comerciales)
- Derecho Administrativo (gobierno, permisos, sanciones administrativas)
- Derecho Constitucional (derechos fundamentales, amparo)
- Derecho Tributario (impuestos, fiscal, tributos)

RESPONDE ÚNICAMENTE con el nombre exacto de UNA especialidad.
NO agregues explicaciones.
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      final specialty = response.text?.trim() ?? '';
      return _validateSpecialty(specialty, userMessage);
    } catch (e) {
      print('Error al clasificar especialidad: $e');
      return _classifyByKeywords(userMessage);
    }
  }

  // ========== PREGUNTAS DE SEGUIMIENTO ==========
  
  Future<List<String>> generateFollowUpQuestions(String userMessage) async {
    try {
      final prompt = '''
Basándote en esta consulta legal específica, genera 3 preguntas de seguimiento que un abogado haría:

CONSULTA: "$userMessage"

REQUISITOS PARA LAS PREGUNTAS:
- Específicas al problema legal planteado
- Que ayuden a clarificar detalles jurídicos importantes
- Orientadas a obtener información crucial para el caso
- Comprensibles para el cliente
- Que NO sean genéricas

FORMATO: 
- Una pregunta por línea
- Sin numeración
- Que terminen en "?"
- Máximo 15 palabras por pregunta

EJEMPLO para caso laboral:
¿Recibió notificación por escrito sobre el despido?
¿Cuántos años completos trabajó en la empresa?
¿Le han pagado todas las prestaciones correspondientes?
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      if (response.text != null) {
        final questions = response.text!
            .split('\n')
            .where((line) => line.trim().isNotEmpty && line.trim().endsWith('?'))
            .map((q) => q.trim())
            .take(3)
            .toList();
        
        if (questions.length >= 2) {
          return questions;
        }
      }
      
      return _getSpecificQuestions(userMessage);
    } catch (e) {
      print('Error al generar preguntas de seguimiento: $e');
      return _getSpecificQuestions(userMessage);
    }
  }

  // ========== DETECCIÓN DE URGENCIA ==========
  
  Future<bool> isUrgentConsultation(String userMessage) async {
    try {
      final prompt = '''
Determina si esta consulta legal requiere atención URGENTE:

"$userMessage"

CRITERIOS DE URGENCIA (responder SÍ si cumple cualquiera):
🚨 URGENTE:
- Detención, arresto, citación judicial inmediata
- Violencia doméstica, amenazas físicas actuales
- Desalojos en curso o próximos (menos de 7 días)
- Plazos judiciales venciendo (menos de 5 días)
- Accidentes graves recientes (menos de 72 horas)
- Despidos con riesgo de perder derechos laborales
- Embargos, medidas cautelares en ejecución
- Negligencia médica con riesgo de vida
- Situaciones que requieren medidas cautelares inmediatas
- Procesos penales activos
- Deadlines legales críticos

🕐 NO URGENTE:
- Consultas generales sobre derechos
- Planificación legal futura
- Dudas sobre procedimientos
- Casos sin plazos inmediatos

¿Es URGENTE? Responde SOLO: SÍ o NO
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      final result = response.text?.trim().toUpperCase();
      return result == 'SÍ' || result == 'SI' || result == 'YES';
    } catch (e) {
      print('Error al verificar urgencia: $e');
      return _checkUrgencyByKeywords(userMessage);
    }
  }

  // ========== RESUMEN PARA ABOGADOS ==========
  
  Future<String> generateCaseSummary(List<String> messages) async {
    try {
      final conversationText = messages.take(10).join('\n\n---MENSAJE---\n\n');
      
      final prompt = '''
Genera un resumen profesional para abogados de esta conversación legal:

CONVERSACIÓN:
$conversationText

FORMATO OBLIGATORIO:
**👤 CLIENTE:** [Perfil breve del consultante]

**⚖️ PROBLEMA PRINCIPAL:** [Resumen específico del problema legal]

**🏛️ ESPECIALIDAD:** [Área legal específica]

**🚨 URGENCIA:** [Baja/Media/Alta] - [Justificación específica]

**📋 HECHOS RELEVANTES:**
• [Hecho importante 1]
• [Hecho importante 2]
• [Hecho importante 3]

**📄 DOCUMENTACIÓN:** [Documentos mencionados o necesarios]

**🎯 RECOMENDACIONES:**
• [Acción específica 1]
• [Acción específica 2]

**💡 OBSERVACIONES:** [Comentarios adicionales del abogado]

Máximo 250 palabras. Sé específico y profesional.
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      return response.text ?? _generateDetailedSummary(messages);
    } catch (e) {
      print('Error al generar resumen: $e');
      return _generateDetailedSummary(messages);
    }
  }

  // ========== ANÁLISIS LEGAL AVANZADO (PARA ABOGADOS) ==========
  
  Future<String> getLegalAnalysisForLawyers(String clientMessage) async {
    try {
      final prompt = '''
Como asistente legal especializado para abogados, analiza esta consulta de cliente:

CONSULTA DEL CLIENTE: "$clientMessage"

PROPORCIONA ANÁLISIS PROFESIONAL:

**🔍 ANÁLISIS JURÍDICO:**
[Análisis técnico legal profundo]

**📚 NORMATIVA APLICABLE:**
[Leyes, códigos y normativas relevantes]

**⚖️ PRECEDENTES:**
[Jurisprudencia o casos similares]

**🎯 ESTRATEGIA SUGERIDA:**
[Enfoque legal recomendado]

**⚠️ RIESGOS LEGALES:**
[Posibles complicaciones]

**💰 CONSIDERACIONES ECONÓMICAS:**
[Costos, honorarios, daños potenciales]

**📋 PASOS PROCESALES:**
[Procedimiento legal a seguir]

**🕐 PLAZOS CRÍTICOS:**
[Deadlines importantes]

Máximo 400 palabras. Usa terminología jurídica profesional.
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      return response.text ?? 'Error al generar análisis profesional.';
    } catch (e) {
      print('Error en análisis para abogados: $e');
      return 'Error al generar análisis profesional.';
    }
  }

  // ========== MÉTODOS AUXILIARES Y FALLBACKS ==========
  
  String _getInvalidQueryResponse() {
    return '''
🤖 **Asistente Legal IA**

❌ **Tu mensaje no parece ser una consulta legal específica.**

📝 **Para ayudarte necesito que:**
• Describas un problema legal concreto
• Menciones si involucra contratos, trabajo, familia, etc.
• Proporciones detalles de tu situación
• Indiques si hay fechas límite o urgencias

✅ **Ejemplos de consultas válidas:**
• "Me despidieron sin justificación, ¿qué derechos tengo?"
• "Mi arrendador quiere desalojarme ilegalmente"
• "Firmé un contrato y la otra parte no cumple"
• "Necesito asesoría sobre custodia de mis hijos"
• "Tuve un accidente y el seguro no quiere pagar"

💡 **Recuerda:** Soy especialista en temas legales. Para otros temas, usa ChatGPT o Google.

🔄 **Por favor, reformula tu consulta con un problema legal específico.**
''';
  }

  bool _isValidLegalQueryByKeywords(String userMessage) {
    final lowerMessage = userMessage.toLowerCase().trim();
    
    // Mensajes muy cortos
    if (lowerMessage.length < 8) {
      return false;
    }
    
    // Saludos simples sin contenido legal
    final invalidPatterns = [
      RegExp(r'^(hola|hi|hello|buenos días|buenas tardes|buenas noches)\.?$'),
      RegExp(r'^(¿cómo estás\?|how are you\?|¿qué tal\?)$'),
      RegExp(r'^(gracias|thanks|ok|bien|perfecto)\.?$'),
      RegExp(r'^(dame un resumen|ayúdame|necesito ayuda)\.?$'),
      RegExp(r'^(consulta|pregunta|duda)\.?$'),
    ];
    
    for (var pattern in invalidPatterns) {
      if (pattern.hasMatch(lowerMessage)) {
        return false;
      }
    }
    
    // Palabras clave legales que indican validez
    final legalKeywords = [
      // Términos legales generales
      'abogado', 'demanda', 'contrato', 'derecho', 'legal', 'ley', 'juicio',
      'tribunal', 'justicia', 'delito', 'penal', 'civil', 'denuncia', 'querella',
      
      // Derecho laboral
      'despido', 'trabajo', 'empleado', 'salario', 'sueldo', 'empresa', 'jefe',
      'laboral', 'prestaciones', 'vacaciones', 'horas extra', 'renuncia',
      
      // Derecho familiar
      'divorcio', 'custodia', 'alimentos', 'matrimonio', 'hijos', 'familia',
      'esposo', 'esposa', 'pareja', 'separación', 'pensión alimenticia',
      
      // Derecho civil
      'propiedad', 'arrendamiento', 'alquiler', 'inquilino', 'propietario',
      'casa', 'departamento', 'terreno', 'vecino', 'construcción',
      
      // Responsabilidad civil y seguros
      'accidente', 'seguro', 'indemnización', 'daños', 'responsabilidad',
      'choque', 'lesiones', 'hospital', 'médico', 'negligencia', 'mala praxis',
      
      // Derecho comercial
      'sociedad', 'comercial', 'negocio', 'cliente', 'proveedor', 'factura',
      'deuda', 'pago', 'crédito', 'banco', 'financiero',
      
      // Derecho administrativo
      'gobierno', 'municipio', 'permiso', 'licencia', 'multa', 'sanción',
      'trámite', 'documento', 'registro', 'certificado',
      
      // Derecho penal
      'robo', 'hurto', 'fraude', 'estafa', 'amenaza', 'agresión', 'violencia',
      'policía', 'fiscal', 'ministerio público', 'investigación', 'detenido',
      
      // Otros términos
      'testamento', 'herencia', 'sucesión', 'notario', 'escritura',
      'impuesto', 'tributario', 'sri', 'deuda tributaria', 'declaración',
      'amparo', 'constitucional', 'derechos humanos', 'libertad',
    ];
    
    // Verificar si contiene al menos una palabra clave legal
    bool hasLegalKeyword = legalKeywords.any((keyword) => 
      lowerMessage.contains(keyword)
    );
    
    // También buscar patrones que indican problemas legales
    final legalPatterns = [
      'me despidieron',
      'no me pagan',
      'firmé un contrato',
      'tengo un problema con',
      'me demandaron',
      'quiero demandar',
      'me discriminan',
      'no cumple el contrato',
      'me estafaron',
      'tuve un accidente',
      'me operaron mal',
      'mi ex no paga',
      'el arrendador',
      'el inquilino',
      'me multaron',
      'tengo deudas',
    ];
    
    bool hasLegalPattern = legalPatterns.any((pattern) => 
      lowerMessage.contains(pattern)
    );
    
    return hasLegalKeyword || hasLegalPattern;
  }

  String _validateSpecialty(String aiResponse, String userMessage) {
    final validSpecialties = [
      'Derecho Civil', 'Derecho Penal', 'Derecho Laboral', 'Derecho Familiar',
      'Derecho Comercial', 'Derecho Administrativo', 'Derecho Constitucional', 
      'Derecho Tributario'
    ];
    
    // Buscar coincidencia exacta o parcial
    for (String specialty in validSpecialties) {
      if (aiResponse.toLowerCase().contains(specialty.toLowerCase()) ||
          specialty.toLowerCase().contains(aiResponse.toLowerCase())) {
        return specialty;
      }
    }
    
    // Si no hay coincidencia, usar clasificación por palabras clave
    return _classifyByKeywords(userMessage);
  }

  String _classifyByKeywords(String userMessage) {
    if (!_isValidLegalQueryByKeywords(userMessage)) {
      return 'Consulta No Válida';
    }
    
    final lowerMessage = userMessage.toLowerCase();
    
    // Derecho médico/negligencia → Civil
    if (lowerMessage.contains('médico') || lowerMessage.contains('hospital') || 
        lowerMessage.contains('operación') || lowerMessage.contains('cirugía') ||
        lowerMessage.contains('mala praxis') || lowerMessage.contains('negligencia') ||
        lowerMessage.contains('tratamiento') || lowerMessage.contains('clínica')) {
      return 'Derecho Civil';
    }
    
    // Derecho penal
    if (lowerMessage.contains('delito') || lowerMessage.contains('penal') || 
        lowerMessage.contains('robo') || lowerMessage.contains('denuncia') ||
        lowerMessage.contains('policía') || lowerMessage.contains('fiscal') ||
        lowerMessage.contains('hurto') || lowerMessage.contains('fraude') ||
        lowerMessage.contains('estafa') || lowerMessage.contains('amenaza') ||
        lowerMessage.contains('agresión') || lowerMessage.contains('violencia')) {
      return 'Derecho Penal';
    }
    
    // Derecho laboral
    if (lowerMessage.contains('trabajo') || lowerMessage.contains('despido') || 
        lowerMessage.contains('laboral') || lowerMessage.contains('empleado') ||
        lowerMessage.contains('sueldo') || lowerMessage.contains('empresa') ||
        lowerMessage.contains('jefe') || lowerMessage.contains('salario') ||
        lowerMessage.contains('prestaciones') || lowerMessage.contains('renuncia') ||
        lowerMessage.contains('vacaciones') || lowerMessage.contains('horas extra')) {
      return 'Derecho Laboral';
    }
    
    // Derecho familiar
    if (lowerMessage.contains('familia') || lowerMessage.contains('divorcio') || 
        lowerMessage.contains('custodia') || lowerMessage.contains('alimentos') ||
        lowerMessage.contains('matrimonio') || lowerMessage.contains('hijos') ||
        lowerMessage.contains('esposo') || lowerMessage.contains('esposa') ||
        lowerMessage.contains('pareja') || lowerMessage.contains('separación') ||
        lowerMessage.contains('pensión alimenticia')) {
      return 'Derecho Familiar';
    }
    
    // Derecho comercial
    if (lowerMessage.contains('empresa') || lowerMessage.contains('sociedad') ||
        lowerMessage.contains('comercial') || lowerMessage.contains('negocio') ||
        lowerMessage.contains('cliente') || lowerMessage.contains('proveedor') ||
        lowerMessage.contains('factura') || lowerMessage.contains('comercio')) {
      return 'Derecho Comercial';
    }
    
    // Derecho tributario
    if (lowerMessage.contains('impuesto') || lowerMessage.contains('tributario') || 
        lowerMessage.contains('fiscal') || lowerMessage.contains('sri') ||
        lowerMessage.contains('declaración') || lowerMessage.contains('deuda tributaria')) {
      return 'Derecho Tributario';
    }
    
    // Derecho administrativo
    if (lowerMessage.contains('gobierno') || lowerMessage.contains('municipio') ||
        lowerMessage.contains('permiso') || lowerMessage.contains('licencia') ||
        lowerMessage.contains('multa') || lowerMessage.contains('sanción') ||
        lowerMessage.contains('trámite') || lowerMessage.contains('registro')) {
      return 'Derecho Administrativo';
    }
    
    // Default: Derecho Civil
    return 'Derecho Civil';
  }

  String _getSpecificLegalResponse(String userMessage) {
    final specialty = _classifyByKeywords(userMessage);
    
    if (specialty == 'Consulta No Válida') {
      return _getInvalidQueryResponse();
    }
    
    final lowerMessage = userMessage.toLowerCase();
    
    // Casos médicos/negligencia
    if (lowerMessage.contains('operación') || lowerMessage.contains('operado') || 
        lowerMessage.contains('médico') || lowerMessage.contains('hospital') ||
        lowerMessage.contains('cirugía') || lowerMessage.contains('clínica')) {
      return '''
🏛️ **Área Legal:** Responsabilidad Civil Médica

📋 **Análisis Legal:** Su caso involucra posible negligencia médica o mala praxis. Los errores médicos pueden generar responsabilidad civil del profesional y la institución.

⚡ **Acciones Inmediatas:**
• Solicite INMEDIATAMENTE su historial clínico completo
• No firme documentos del hospital sin revisión legal
• Documente todas las secuelas y gastos médicos adicionales
• Obtenga segunda opinión médica por escrito

📄 **Documentos Necesarios:**
• Historia clínica completa del procedimiento
• Consentimientos informados firmados
• Facturas de gastos médicos adicionales
• Informes de otros médicos sobre complicaciones

⚠️ **Nivel de Urgencia:** ALTO - Las demandas por negligencia médica tienen plazos de prescripción de 3 años desde conocimiento del daño.

🎯 **Recomendación:** Consulte inmediatamente un abogado especializado en responsabilidad médica para evaluar viabilidad de demanda por daños y perjuicios.
''';
    }
    
    // Casos penales
    if (lowerMessage.contains('delito') || lowerMessage.contains('penal') || 
        lowerMessage.contains('robo') || lowerMessage.contains('denuncia') ||
        lowerMessage.contains('policía') || lowerMessage.contains('fiscal')) {
      return '''
🏛️ **Área Legal:** Derecho Penal

📋 **Análisis Legal:** Su situación involucra aspectos del derecho penal. Es fundamental proteger sus derechos desde el primer momento del proceso.

⚡ **Acciones Inmediatas:**
• NO declare sin presencia de abogado defensor
• Solicite defensoría pública si no puede costear abogado privado
• Reúna todas las evidencias que lo favorezcan
• Identifique testigos favorables a su versión

📄 **Documentos Necesarios:**
• Cédula de identidad actualizada
• Denuncias o acusaciones presentadas
• Comunicaciones oficiales recibidas
• Evidencias documentales del caso

⚠️ **Nivel de Urgencia:** ALTO - En procesos penales cada declaración puede afectar su defensa. Tiempo crítico para construir estrategia.

🎯 **Recomendación:** Contacte urgentemente un abogado penalista. Evite dar declaraciones hasta tener defensa técnica adecuada.
''';
    }
    
    // Casos laborales
    if (lowerMessage.contains('trabajo') || lowerMessage.contains('despido') || 
        lowerMessage.contains('laboral') || lowerMessage.contains('empleado') ||
        lowerMessage.contains('sueldo') || lowerMessage.contains('empresa')) {
      return '''
🏛️ **Área Legal:** Derecho Laboral

📋 **Análisis Legal:** Su consulta involucra derechos laborales protegidos por el Código del Trabajo. Los empleadores deben respetar garantías mínimas establecidas por ley.

⚡ **Acciones Inmediatas:**
• Conserve TODOS los documentos laborales originales
• No firme renuncias o documentos sin revisar con abogado
• Calcule prestaciones e indemnizaciones adeudadas
• Registre cualquier irregularidad o presión laboral

📄 **Documentos Necesarios:**
• Contrato de trabajo original
• Últimas tres colillas de pago
• Comunicaciones escritas de la empresa
• Registro de horarios y horas trabajadas

⚠️ **Nivel de Urgencia:** MEDIO-ALTO - Tiene 30 días para reclamar derechos laborales desde terminación de contrato.

🎯 **Recomendación:** Acuda al Ministerio del Trabajo para mediación laboral o consulte abogado laboralista para evaluar demanda judicial.
''';
    }
    
    // Casos familiares
    if (lowerMessage.contains('familia') || lowerMessage.contains('divorcio') || 
        lowerMessage.contains('custodia') || lowerMessage.contains('alimentos') ||
        lowerMessage.contains('matrimonio') || lowerMessage.contains('hijos')) {
      return '''
🏛️ **Área Legal:** Derecho de Familia

📋 **Análisis Legal:** Su situación involucra derecho de familia. Estos casos requieren consideración especial del interés superior de menores y derechos familiares.

⚡ **Acciones Inmediatas:**
• Documente situación actual de menores involucrados
• Reúna evidencias de ingresos de ambas partes
• Evite conflictos frente a los hijos
• Considere mediación familiar antes de juicio

📄 **Documentos Necesarios:**
• Certificados de nacimiento de hijos
• Comprobantes de ingresos actualizados
• Acta de matrimonio o unión de hecho
• Inventario de bienes matrimoniales

⚠️ **Nivel de Urgencia:** MEDIO - Proteger bienestar de menores es prioritario. Algunos trámites tienen plazos específicos.

🎯 **Recomendación:** Busque mediación en Centro de Mediación Familiar o consulte abogado especialista en familia para evaluar opciones legales.
''';
    }
    
    // Respuesta general para consultas válidas sin categoría específica
    return '''
🏛️ **Área Legal:** $specialty

📋 **Análisis Legal:** He identificado que su consulta se relaciona con $specialty. Para brindarle asesoría específica necesito más detalles de su situación.

⚡ **Acciones Inmediatas:**
• Proporcione más detalles específicos del problema
• Indique fechas relevantes de los hechos
• Mencione si existen plazos urgentes
• Especifique el resultado que busca obtener

📄 **Documentos Necesarios:**
• Documentos relacionados directamente al caso
• Comunicaciones relevantes con otras partes
• Contratos o acuerdos previos existentes

⚠️ **Nivel de Urgencia:** Por determinar - Necesito más información para evaluar urgencia del caso.

🎯 **Recomendación:** Amplíe su consulta con detalles específicos para recibir orientación legal más precisa y útil.
''';
  }

  List<String> _getSpecificQuestions(String userMessage) {
    final specialty = _classifyByKeywords(userMessage);
    final lowerMessage = userMessage.toLowerCase();
    
    // Preguntas específicas para casos médicos/negligencia
    if (lowerMessage.contains('operación') || lowerMessage.contains('médico') || 
        lowerMessage.contains('hospital') || lowerMessage.contains('cirugía')) {
      return [
        '¿Firmó un consentimiento informado antes del procedimiento médico?',
        '¿Le explicaron claramente todos los riesgos y complicaciones posibles?',
        '¿Tiene registros médicos completos de antes y después del procedimiento?'
      ];
    }
    
    // Preguntas para casos laborales
    if (lowerMessage.contains('trabajo') || lowerMessage.contains('despido') || 
        lowerMessage.contains('laboral') || lowerMessage.contains('empleado')) {
      return [
        '¿Recibió notificación escrita sobre el despido con las causas específicas?',
        '¿Cuántos años completos y meses trabajó en la empresa?',
        '¿Le han pagado todas las prestaciones laborales correspondientes?'
      ];
    }
    
    // Preguntas para casos familiares
    if (lowerMessage.contains('familia') || lowerMessage.contains('divorcio') || 
        lowerMessage.contains('custodia') || lowerMessage.contains('matrimonio')) {
      return [
        '¿Tienen hijos menores de edad involucrados en la situación?',
        '¿Existe régimen de sociedad conyugal o separación de bienes?',
        '¿Han intentado previamente mediación familiar para resolver el conflicto?'
      ];
    }
    
    // Preguntas para casos penales
    if (lowerMessage.contains('delito') || lowerMessage.contains('penal') || 
        lowerMessage.contains('denuncia') || lowerMessage.contains('policía')) {
      return [
        '¿Ha sido formalmente citado por alguna autoridad judicial?',
        '¿Tiene conocimiento de investigación penal en su contra?',
        '¿Cuenta con evidencias o testigos que respalden su versión?'
      ];
    }
    
    // Preguntas para casos de contratos/civil
    if (lowerMessage.contains('contrato') || lowerMessage.contains('civil') || 
        lowerMessage.contains('acuerdo') || lowerMessage.contains('deuda')) {
      return [
        '¿El contrato o acuerdo está firmado por ambas partes?',
        '¿Cuál es el monto exacto de dinero involucrado?',
        '¿Ha intentado resolver la situación directamente con la otra parte?'
      ];
    }
    
    // Preguntas generales por especialidad
    switch (specialty) {
      case 'Derecho Comercial':
        return [
          '¿Su empresa está legalmente constituida y registrada?',
          '¿El problema involucra contratos comerciales específicos?',
          '¿Hay documentos que respalden la relación comercial?'
        ];
      
      case 'Derecho Tributario':
        return [
          '¿Está al día con sus declaraciones al SRI?',
          '¿Ha recibido notificaciones oficiales sobre deudas tributarias?',
          '¿Tiene comprobantes de pagos realizados al SRI?'
        ];
      
      case 'Derecho Administrativo':
        return [
          '¿Ha agotado la vía administrativa antes de acudir a tribunales?',
          '¿Tiene copias de todas las comunicaciones con la entidad pública?',
          '¿Existen plazos específicos para impugnar la decisión administrativa?'
        ];
      
      default:
        return [
          '¿Cuándo ocurrieron exactamente los hechos que describe?',
          '¿Tiene testigos o evidencias documentales de la situación?',
          '¿Ha intentado resolver este problema por la vía extrajudicial?'
        ];
    }
  }

  bool _checkUrgencyByKeywords(String userMessage) {
    final urgentKeywords = [
      // Términos de urgencia temporal
      'urgente', 'inmediato', 'ya', 'hoy', 'mañana', 'esta semana',
      
      // Situaciones críticas
      'arresto', 'detenido', 'citación judicial', 'audiencia',
      'violencia', 'amenaza', 'golpes', 'maltrato',
      'desalojo', 'embargo', 'congelaron', 'bloquearon',
      'plazo vencido', 'fecha límite', 'deadline',
      
      // Emergencias médicas/accidentes
      'accidente', 'emergencia', 'hospitalizado', 'grave',
      'operación mal', 'casi muere', 'coma', 'negligencia grave',
      
      // Situaciones laborales urgentes
      'me despidieron hoy', 'no me pagan', 'cerraron la empresa',
      
      // Situaciones familiares urgentes
      'se llevó a los niños', 'no puedo ver a mis hijos',
      'violencia doméstica', 'orden de alejamiento',
      
      // Situaciones penales urgentes
      'me van a demandar', 'proceso penal', 'investigación'
    ];
    
    final lowerMessage = userMessage.toLowerCase();
    return urgentKeywords.any((keyword) => lowerMessage.contains(keyword));
  }

  String _generateDetailedSummary(List<String> messages) {
    if (messages.isEmpty) {
      return 'No hay conversación para resumir.';
    }
    
    final firstMessage = messages.first;
    final specialty = _classifyByKeywords(firstMessage);
    final isUrgent = _checkUrgencyByKeywords(firstMessage);
    
    return '''
**👤 CLIENTE:** Usuario con consulta sobre $specialty

**⚖️ PROBLEMA PRINCIPAL:** ${firstMessage.length > 150 ? firstMessage.substring(0, 150) + '...' : firstMessage}

**🏛️ ESPECIALIDAD:** $specialty

**🚨 URGENCIA:** ${isUrgent ? 'Alta - Requiere atención prioritaria' : 'Media - Puede ser atendida en horario regular'}

**📋 HECHOS RELEVANTES:**
• Total de ${messages.length} intercambios en la conversación
• Cliente ha proporcionado detalles específicos del caso
• Se requiere revisión de documentación legal

**📄 DOCUMENTACIÓN:** Por determinar según desarrollo del caso

**🎯 RECOMENDACIONES:**
• Revisar documentos específicos mencionados por el cliente
• Evaluar viabilidad legal del caso planteado
• Proporcionar asesoría legal especializada en $specialty

**💡 OBSERVACIONES:** Caso requiere atención de abogado especializado para evaluación detallada y estrategia legal apropiada.
''';
  }
}