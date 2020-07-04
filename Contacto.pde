/*
  Clase que representa una interaccion (un contacto) entre dos individuos
*/

class Contacto{
  Empleado individuoUno;
  Empleado individuoDos;  
  boolean tipo;  // Si el valor es true, el contacto es efectivo
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
