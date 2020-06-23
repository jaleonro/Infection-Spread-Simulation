import java.lang.Math;
import java.util.Random;
import java.util.*;

int nIndividuos;
int tiempo;
List<Contacto> contactos = new ArrayList<Contacto>();
List<Empleado> individuos = new ArrayList<Empleado>();
float distanciaMax,distanciaMin;
float probInfeccion,probSintomatico;

float X1, Y1;
float X2, Y2;

void setup(){
  size(650, 650);
  background(0);
  frameRate(1);
  PFont font = loadFont("AgencyFB-Reg-14.vlw");
  textFont(font);
  X1 = 50;
  X2 = width - X1;
  Y1 = 50;
  Y2 = height - Y1;
  tiempo = 0;
  nIndividuos = 20;
  probInfeccion = 1.0;
  probSintomatico = 0.7;
  generarNodos();
}

void draw(){
  if(frameCount == 1){
    dibujar();
  }
  if(frameCount%4==0){ 
    tiempo++;
    simularContactos();
    dibujar();
    simularContagios();
    evaluarCambiosDeEstado();
  }  
}


void generarNodos(){  
  for (int i = 0; i < nIndividuos; i++) {
    float random = (float) Math.random();
    float posX = map(random, 0.0, 1.0, X1, X2);
    random = (float) Math.random();
    float posY = map(random, 0.0, 1.0, Y1, Y2);  
    Random rand = new Random();
    int estado = rand.nextInt(4);
    Empleado nuevoIndividuo = new Empleado(i, estado, posX, posY, -1, -1, 0.0);
    individuos.add(nuevoIndividuo);
  }  
  distanciaMax = Float.MIN_VALUE;
  distanciaMin = Float.MAX_VALUE;
  for (int i = 0; i < nIndividuos; i++) {
    for (int j = i+1; j < nIndividuos; j++) {   
      Empleado individuoUno = individuos.get(i);
      Empleado individuoDos = individuos.get(j);
      float distancia = dist(individuoUno.posX, individuoUno.posY, individuoDos.posX, individuoDos.posY);
      if (distancia > distanciaMax){
        distanciaMax = distancia;
      }
      if (distancia < distanciaMin){
        distanciaMin = distancia;
      }
    }
  }
}

void dibujar(){
  background(0);
  pushStyle();
  fill(255);
  textAlign(LEFT);
  textSize(26);
  text("Tiempo: "+ tiempo + " Hrs", (X2 - X1)/2, 30);
  popStyle(); 
  for (Contacto contacto : contactos) {
    boolean tipoContacto = contacto.tipo;
    color colorArista;
    if(tipoContacto){//contacto efectivo
      colorArista = color(255, 0, 0);//rojo
    }else{
      colorArista = color(0, 0, 255);
    }      
    pushStyle();
    strokeWeight(3);
    stroke(colorArista);
    line(contacto.individuoUno.posX, contacto.individuoUno.posY, contacto.individuoDos.posX, contacto.individuoDos.posY);
    popStyle();
  }
  for (Empleado individuo : individuos) {
    color colorNodo;
    String etiquetaEstado;
    switch (individuo.estado) {
      case 0:  {colorNodo = color(0, 255, 0);
                etiquetaEstado = "S";}
               break;
      case 1:  {colorNodo = color(255, 50, 0);
                etiquetaEstado = "Ip";}
               break;
      case 2:  {colorNodo = color(255, 0, 247);
                etiquetaEstado = "Is";}
               break;
      case 3:  {colorNodo = color(141, 30, 131);        
                etiquetaEstado = "Ia";}
               break;
      case 4:  {colorNodo = color(255, 255, 255);        
                etiquetaEstado = "Ra";}
               break;
      case 5:  {colorNodo = color(220, 255, 0);        
                etiquetaEstado = "C";}
               break;
      default: {colorNodo = color(4, 248, 252);
                etiquetaEstado = "S";}
               break;
      }
    pushStyle();
    fill(colorNodo); 
    ellipseMode(RADIUS);
    ellipse(individuo.posX,individuo.posY, 9, 9);
    popStyle();
    
    pushStyle();
    fill(0);
    textAlign(CENTER,CENTER);  
    textSize(14);
    text(etiquetaEstado, individuo.posX, individuo.posY);
    popStyle();
  } 
}

void simularContactos(){
  contactos = new ArrayList<Contacto>();
  for (int i = 0; i < nIndividuos; i++) {
    for (int j = i+1; j < nIndividuos; j++) {   
      Empleado individuoUno = individuos.get(i);
      Empleado individuoDos = individuos.get(j);      
      float distanciaIndividuos = dist(individuoUno.posX, individuoUno.posY, individuoDos.posX, individuoDos.posY);
      float probabilidadContacto = map((1/distanciaIndividuos), (1/distanciaMax), (1/distanciaMin), 0.0, 1.0);
      float random = (float) Math.random();
      println("prob");
      println(probabilidadContacto);
      println("rand");
      println(random);
      if (random <= probabilidadContacto){
        Random rand = new Random();
        int duracionDelContacto = rand.nextInt(60) + 1;
        boolean tipoContacto = getTipoDeContacto(individuoUno, individuoDos);
        Contacto nuevoContacto = new Contacto(individuoUno, individuoDos, tipoContacto, duracionDelContacto, 0);
        if(!(individuoUno.estado == 5 || individuoDos.estado == 5)){//individuosEnCuarentena
          contactos.add(nuevoContacto); 
        }               
      }
    }
  }
}

void simularContagios(){
  for (Contacto contacto : contactos) {
    if(contacto.tipo){
      float random = (float) Math.random();
      if (random <= probInfeccion){
        Random rand = new Random();
        int duracionIncubacion = rand.nextInt(14) + 1;
        if(contacto.individuoUno.estado == 0){
          contacto.individuoUno.estado = 1;
          contacto.individuoUno.tiempoDeContagio = tiempo;
          contacto.individuoUno.duracionIncubacion = duracionIncubacion;
        }else{
          contacto.individuoDos.estado = 1;
          contacto.individuoDos.tiempoDeContagio = tiempo;
          contacto.individuoDos.duracionIncubacion = duracionIncubacion;
        }   
      }
    }  
  }
}

boolean getTipoDeContacto(Empleado individuoUno, Empleado individuoDos){
  boolean tipoDeContacto;
  if(individuoUno.estado == 0 || individuoDos.estado == 0){
     tipoDeContacto = true; 
  }
  else{
    tipoDeContacto = false;
  }
  return tipoDeContacto;
}

void evaluarCambiosDeEstado(){
  for (Empleado individuo : individuos) {    
    if (individuo.estado == 1){
      if (individuo.tiempoDeContagio + individuo.duracionIncubacion == tiempo){
        float random = (float) Math.random();
        if (random <= probSintomatico){
          individuo.estado = 2;
        }else{
          individuo.estado = 3;
        }
      }
    }    
    if (individuo.estado == 2){
      if (individuo.tiempoDeContagio + individuo.duracionIncubacion + 8 == tiempo){
        individuo.estado = 5;
      }
    }
    if (individuo.estado == 3){
      if (individuo.tiempoDeContagio + individuo.duracionIncubacion + 80 == tiempo){
        individuo.estado = 4;
      }
    }
  }  
}
