/*
  Clase que representa a un individuo en la simulacion
*/

class Empleado{
  int id;  
  /*
  Posibles estados del individuo:
    0 - Susceptible
    1 - Infectado pre-sintomatico
    2 - Infectado sintomatico
    3 - Infectado asintomatico
    4 - En Cuarentena
*/  
  int estado;
  Float posX;               // Posicion x en la pantalla
  Float posY;               // Posicion y en la pantalla
  int tiempoDeContagio;
  int duracionIncubacion;
  Float probContagiar_se;   // Probabilidad de contagiar o ser contagiado (Valor entre 0 y 1)
  int sociabilidad;
  
  public Empleado(int id, int estado, Float posX, Float posY, int tiempoDeContagio, int duracionIncubacion, Float probContagiar_se, int sociabilidad){
    this.id = id;
    this.estado = estado;
    this.posX = posX;
    this.posY = posY;
    this.tiempoDeContagio = tiempoDeContagio;
    this.duracionIncubacion = duracionIncubacion;
    this.probContagiar_se = probContagiar_se;
    this.sociabilidad = sociabilidad;
  }
}
