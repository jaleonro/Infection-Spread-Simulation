class Empleado{
  int id;
  int estado;//Susceptible:0, Infectado pre-sintomatico:1, Infectado sintomatico:2, Infectado asintomatico:3, Recuperado asintomatico:4, En cuarentena: 5
  Float posX;
  Float posY;
  int tiempoDeContagio;
  int duracionIncubacion;
  Float probContagiar_se;
  
  public Empleado(int id, int estado, Float posX, Float posY, int tiempoDeContagio, int duracionIncubacion, Float probContagiar_se){
    this.id = id;
    this.estado = estado;
    this.posX = posX;
    this.posY = posY;
    this.tiempoDeContagio = tiempoDeContagio;
    this.duracionIncubacion = duracionIncubacion;
    this.probContagiar_se = probContagiar_se;
  }
}
