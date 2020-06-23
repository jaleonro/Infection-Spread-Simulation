class Contacto{
  Empleado individuoUno;
  Empleado individuoDos;
  boolean tipo;//true = contacto efectivo
  int duracion;
  float distancia;
  
  public Contacto(Empleado individuoUno, Empleado individuoDos, boolean tipo, int duracion, float distancia){
    this.individuoUno = individuoUno;
    this.individuoDos = individuoDos;
    this.tipo = tipo;
    this.duracion = duracion;
    this.distancia = distancia;
  }
}
