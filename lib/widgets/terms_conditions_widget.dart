import 'package:flutter/material.dart';

class TermsAndConditionsWidget extends StatelessWidget {
  final bool showAsDialog;
  final VoidCallback? onAccept;
  final VoidCallback? onCancel;

  const TermsAndConditionsWidget({
    Key? key,
    this.showAsDialog = true,
    this.onAccept,
    this.onCancel,
  }) : super(key: key);

  // Método estático para mostrar como dialog
  static Future<bool?> showTermsDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            height: MediaQuery.of(context).size.height * 0.8,
            width: MediaQuery.of(context).size.width * 0.9,
            child: TermsAndConditionsWidget(
              showAsDialog: true,
              onAccept: () => Navigator.of(context).pop(true),
              onCancel: () => Navigator.of(context).pop(false),
            ),
          ),
        );
      },
    );
  }

  // Método estático para navegar a pantalla completa
  static Future<bool?> showFullScreen(BuildContext context) {
    return Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('Términos y Condiciones'),
            elevation: 0,
          ),
          body: TermsAndConditionsWidget(
            showAsDialog: false,
            onAccept: () => Navigator.of(context).pop(true),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (showAsDialog) {
      return _buildDialogContent(context);
    } else {
      return _buildFullScreenContent(context);
    }
  }

  Widget _buildDialogContent(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Términos y Condiciones',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: onCancel ?? () => Navigator.of(context).pop(false),
              ),
            ],
          ),
          Divider(),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              child: _buildTermsContent(),
            ),
          ),
          SizedBox(height: 16),
          
          // Buttons
          Row(
            children: [
              if (onCancel != null)
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    child: Text('Cancelar'),
                  ),
                ),
              if (onCancel != null) SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onAccept ?? () => Navigator.of(context).pop(true),
                  child: Text('Aceptar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFullScreenContent(BuildContext context) {
    return Column(
      children: [
        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: _buildTermsContent(),
          ),
        ),
        
        // Bottom button
        if (onAccept != null)
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: onAccept,
              child: Text('Aceptar y Continuar'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTermsContent() {
    return Text(
      _getTermsAndConditionsText(),
      style: TextStyle(
        fontSize: 14,
        height: 1.6,
      ),
      textAlign: TextAlign.justify,
    );
  }

  // Texto completo de términos y condiciones
  String _getTermsAndConditionsText() {
    return '''TÉRMINOS Y CONDICIONES DE USO DE LA APLICACIÓN IURISMATCH
Última actualización: 17 de junio de 2025

Estos Términos y Condiciones regulan el acceso y uso de la aplicación móvil y/o web denominada IurisMatch (en adelante, la "Aplicación"), administrada por el equipo IurisMatch, (en adelante, "Administradora").

El uso de la Aplicación implica la aceptación plena y sin reservas de los presentes Términos y Condiciones. Si no está de acuerdo con estos términos, debe abstenerse de utilizar la plataforma.

1. OBJETO DE LA APLICACIÓN
IurisMatch es una plataforma digital cuyo objetivo es facilitar el contacto entre:

• Estudiantes de Derecho y pasantes en búsqueda de experiencia profesional.
• Abogados, estudios jurídicos y organizaciones que ofrecen pasantías o vacantes legales.
• Usuarios interesados en acceder a cursos de formación jurídica, foros de debate y otros recursos del ámbito legal.

La plataforma actúa como intermediaria tecnológica, sin participar directamente en las relaciones contractuales, laborales, académicas ni profesionales entre los usuarios.

2. REGISTRO Y ACCESO
Para utilizar los servicios de la Aplicación, el usuario debe registrarse y proporcionar información veraz, completa y actualizada. El usuario es responsable de la confidencialidad de sus credenciales de acceso y del uso de su cuenta.

IurisMatch se reserva el derecho de suspender o eliminar cuentas que incumplan los presentes Términos, proporcionen información falsa o utilicen la plataforma con fines indebidos.

3. SERVICIOS DISPONIBLES
La Aplicación pone a disposición de los usuarios las siguientes funcionalidades:

• Publicación y consulta de oportunidades de pasantías o empleos jurídicos.
• Inscripción y acceso a cursos jurídicos y capacitaciones especializadas.
• Participación en foros de discusión y espacios colaborativos de carácter jurídico.
• Visualización y contacto con perfiles profesionales y académicos.

IurisMatch no garantiza el éxito de ninguna postulación ni la contratación efectiva entre las partes.

4. TARIFAS Y PAGOS
Algunos servicios y contenidos ofrecidos por la Aplicación (como cursos o eventos) pueden estar sujetos al pago de tarifas, las cuales serán informadas previamente de manera clara.

Las tarifas pagadas no son reembolsables, salvo que expresamente se indique lo contrario en casos específicos de cancelación del servicio por parte de la Administradora.

5. RESPONSABILIDADES DEL USUARIO
El usuario se compromete a:

• Usar la plataforma conforme a la ley ecuatoriana y a los principios de buena fe.
• No compartir información falsa, ofensiva, discriminatoria o que infrinja derechos de terceros.
• No utilizar la Aplicación para fines ilegales, comerciales no autorizados o de suplantación de identidad.

6. LIMITACIÓN DE RESPONSABILIDAD
IurisMatch y su representante no se hacen responsables por:

• La veracidad, legalidad o exactitud de la información publicada por usuarios.
• La calidad, duración o condiciones de pasantías, empleos o cursos ofrecidos.
• Daños o perjuicios derivados del uso indebido o inadecuado de la Aplicación.
• Incumplimientos entre usuarios, proveedores o terceros contactados a través de la plataforma.

IurisMatch es una aplicación intermediaria entre usuarios, por lo que las interacciones dependen exclusivamente de estos. La administración procurará restringir y eliminar contenido inadecuado o inapropiado tras ser detectado.

7. AUTORÍA DEL CONTENIDO Y AUSENCIA DE ASESORÍA LEGAL
Los contenidos, opiniones, comentarios, documentos, materiales, artículos, consejos, orientaciones y cualquier información publicada, compartida o divulgada por los usuarios registrados en la Aplicación, sean estos abogados, estudiantes de derecho, pasantes, profesionales del derecho o cualquier otro tipo de usuario, son de exclusiva autoría y responsabilidad de quien los publica.

IurisMatch declara expresamente que:

a) No constituye asesoría legal: Ningún contenido generado por usuarios de la plataforma constituye asesoría legal formal, consulta jurídica profesional ni opinión legal vinculante. Los usuarios que requieran asesoría legal específica deberán consultar directamente con un abogado debidamente habilitado para ejercer la profesión.

b) No representa a la Aplicación: Las opiniones, criterios, interpretaciones legales, comentarios o cualquier manifestación expresada por los usuarios no representan la posición oficial de IurisMatch, ni comprometen la responsabilidad de la Administradora, ni constituyen declaraciones institucionales de la plataforma.

c) Exención de responsabilidad profesional: IurisMatch no asume responsabilidad alguna por las consecuencias, daños, perjuicios o efectos adversos que puedan derivarse del uso, aplicación o interpretación de los contenidos publicados por usuarios en la plataforma.

d) Carácter informativo: Todo contenido disponible en la Aplicación tiene únicamente carácter informativo, educativo y de intercambio académico o profesional, sin constituir en modo alguno asesoramiento legal profesional.

Los usuarios que publiquen contenido legal se comprometen a incluir las advertencias pertinentes sobre el carácter no vinculante de sus publicaciones y la necesidad de consulta profesional especializada para casos específicos. Todo contacto profesional es externo y responsabilidad exclusiva de las partes.

8. PROPIEDAD INTELECTUAL
Todos los contenidos, diseños, logotipos, códigos y elementos visuales de la Aplicación son propiedad de IurisMatch y están protegidos por las leyes de propiedad intelectual de Ecuador. Está prohibida su reproducción, modificación o uso no autorizado.

9. PROTECCIÓN DE DATOS PERSONALES
IurisMatch recolecta y trata datos personales conforme a lo establecido en la Ley Orgánica de Protección de Datos Personales del Ecuador.

Finalidades del tratamiento:
• Gestión de usuarios registrados.
• Envío de información relevante (notificaciones, actualizaciones, cursos, oportunidades).
• Estadísticas y mejoras del servicio.

Derechos del titular de los datos:
El usuario podrá ejercer sus derechos de acceso, rectificación, eliminación, oposición y portabilidad mediante solicitud escrita al correo electrónico indicado abajo.

Los datos no serán compartidos con terceros sin consentimiento expreso, salvo obligación legal.

10. MODIFICACIONES
IurisMatch se reserva el derecho de modificar estos Términos y Condiciones en cualquier momento. Los cambios se notificarán a través de la misma Aplicación o por correo electrónico. El uso continuado implica aceptación de las modificaciones.

11. SOLUCIÓN DE CONTROVERSIAS
En caso de controversias relacionadas con el uso de la Aplicación, las partes acuerdan:

• Buscar una solución amistosa mediante mediación administrada por un centro debidamente acreditado.
• Si la mediación no resulta exitosa en un plazo de 30 días, la controversia se resolverá mediante arbitraje en derecho, conforme a la Ley de Arbitraje y Mediación del Ecuador.

El tribunal arbitral estará compuesto por tres árbitros: uno designado por la parte demandante, otro por la parte demandada, y el tercero elegido por sorteo entre árbitros inscritos en el centro de arbitraje seleccionado.

El laudo arbitral será definitivo, obligatorio e inapelable.

12. LEY APLICABLE Y JURISDICCIÓN
Estos Términos se rigen por las leyes de la República del Ecuador. En todo lo no previsto, se aplicarán las disposiciones del Código Civil, Código de Comercio, Ley de Protección de Datos Personales, Ley de Arbitraje y Mediación, y demás normas aplicables.

13. CONTACTO
Para consultas, sugerencias o ejercicio de derechos en materia de protección de datos, puede contactarse a:

IurisMatch
📧 iurismatch@gmail.com''';
  }
}

// Widget para mostrar enlace a términos y condiciones
class TermsAndConditionsLink extends StatelessWidget {
  final String text;
  final TextStyle? textStyle;
  final bool showAsFullScreen;

  const TermsAndConditionsLink({
    Key? key,
    this.text = 'Ver términos y condiciones',
    this.textStyle,
    this.showAsFullScreen = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (showAsFullScreen) {
          TermsAndConditionsWidget.showFullScreen(context);
        } else {
          TermsAndConditionsWidget.showTermsDialog(context);
        }
      },
      child: Text(
        text,
        style: textStyle ?? TextStyle(
          color: Theme.of(context).primaryColor,
          decoration: TextDecoration.underline,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// Widget para checkbox con términos y condiciones
class TermsAcceptanceCheckbox extends StatefulWidget {
  final bool initialValue;
  final ValueChanged<bool> onChanged;
  final String checkboxText;
  final String linkText;
  final bool showAsFullScreen;

  const TermsAcceptanceCheckbox({
    Key? key,
    this.initialValue = false,
    required this.onChanged,
    this.checkboxText = 'Acepto los términos y condiciones de uso',
    this.linkText = 'Ver términos completos',
    this.showAsFullScreen = false,
  }) : super(key: key);

  @override
  _TermsAcceptanceCheckboxState createState() => _TermsAcceptanceCheckboxState();
}

class _TermsAcceptanceCheckboxState extends State<TermsAcceptanceCheckbox> {
  bool _isAccepted = false;

  @override
  void initState() {
    super.initState();
    _isAccepted = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TermsAndConditionsLink(
          text: widget.linkText,
          showAsFullScreen: widget.showAsFullScreen,
        ),
        SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _isAccepted,
              onChanged: (bool? value) {
                setState(() {
                  _isAccepted = value ?? false;
                });
                widget.onChanged(_isAccepted);
              },
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isAccepted = !_isAccepted;
                  });
                  widget.onChanged(_isAccepted);
                },
                child: Text(
                  widget.checkboxText,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}