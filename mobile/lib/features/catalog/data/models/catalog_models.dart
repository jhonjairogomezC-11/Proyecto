class CatalogItem {
  const CatalogItem({required this.id, required this.nombre});

  final int id;
  final String nombre;

  factory CatalogItem.fromJson(Map<String, dynamic> json) {
    return CatalogItem(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'nombre': nombre};
}

class Departamento extends CatalogItem {
  const Departamento({required super.id, required super.nombre});

  factory Departamento.fromJson(Map<String, dynamic> json) {
    return Departamento(id: json['id'] as int, nombre: json['nombre'] as String);
  }
}

class Municipio extends CatalogItem {
  const Municipio({
    required super.id,
    required super.nombre,
    this.departamento,
  });

  final Departamento? departamento;

  factory Municipio.fromJson(Map<String, dynamic> json) {
    Departamento? dept;
    final deptJson = json['departamento'];
    if (deptJson is Map<String, dynamic>) {
      dept = Departamento.fromJson(deptJson);
    }

    return Municipio(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      departamento: dept,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        if (departamento != null) 'departamento': departamento!.toJson(),
      };
}
