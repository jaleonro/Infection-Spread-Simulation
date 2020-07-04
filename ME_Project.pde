/**
*  UNIVERSIDAD NACIONAL DE COLOMBIA 2020-I  
*
*  Proyecto de Modelos Estocasticos y Simulacion en Computacion
*  y Comunicaciones  
*  
*  Desarrollado por:
    Johanathan Andres Leon Rodriguez
    Jonathan Alexander Carrillo Cortes
    Diego Felipe Rodriguez Chaparro
    Carlos Alberto Nieto Tinoco
    Cristian Yair Carreno Leon
*
*/

import java.lang.Math;
import java.util.Random;
import java.util.*;

// TODO: Variables a constantes

int nIndividuos;
int tiempo;
List<Contacto> contactos = new ArrayList<Contacto>();
List<Empleado> individuos = new ArrayList<Empleado>();
Consts constantes = new Consts();

// Distancia entre individuos
float distanciaMax,distanciaMin;

// Probabilidad de que un individuo sea sintomatico
float probSintomatico;
int tiempoDeRecuperacion; 
int nInicialDeInfectados;

// Variables que contienen el numero de individuos en las diferentes etapas
// de la infeccion
int susceptibles, preSintomaticos, infectadosSintomaticos, infectadosAsintomaticos, recuperadosAsintomaticos, enCuarentena =  0;

float X1, Y1;
float X2, Y2;

/*
  Funcion que se realiza las preparaciones previas antes de iniciar 
  la simulacion (draw)
*/
void setup(){
  size(850, 650);
  background(0);
  frameRate(1);
  PFont font = loadFont("AgencyFB-Reg-14.vlw");
  textFont(font);
  X1 = 100;
  X2 = width - X1;
  Y1 = 100;
  Y2 = height - Y1;
  tiempo = 0;
  nIndividuos = Consts.NUMERO_INDIVIDUOS;
  nInicialDeInfectados = Consts.NUMERO_INICIAL_INFECTADOS;
  preSintomaticos = Consts.NUMERO_INICIAL_INFECTADOS;
  probSintomatico = Consts.PROBABILIDAD_SINTOMATICO;
  tiempoDeRecuperacion = Consts.TIEMPO_RECUPERACION;
  susceptibles = nIndividuos - nInicialDeInfectados;
  generarNodos();
}

/*
  Funcion encargada de dibujar cuadro a cuadro el nuevo estado de los
  individuos.
  Cada 4 segundos actualiza el estado de los individuos.
*/
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
    
    // Las posiciones de cada empleado son aleatortias
    float random = (float) Math.random();
    float posX = map(random, 0.0, 1.0, X1, X2);
    random = (float) Math.random();
    float posY = map(random, 0.0, 1.0, Y1, Y2);  
    Random rand = new Random();
    
    // Todos los individuos inician con estado de Susceptibles
    // Excepto el numero de infectados inicial
    int estado = Consts.SUSCEPTIBLE;
    
    // Determina el numero de cointactos por hora de cada individuo
    int sociabilidad = rand.nextInt(3);
    
    // La probabilidad de contagiar o ser cnotagiado
    float probContagiar_se = (float) Math.random(); 
    Empleado nuevoIndividuo = new Empleado(i, estado, posX, posY, -1, -1, probContagiar_se, sociabilidad);
    individuos.add(nuevoIndividuo);
  }
  
  // Se cambia el estado de los infectados iniciales
  for (int i = 0; i < nInicialDeInfectados; i++) {   
    individuos.get(i).estado = Consts.PRE_SINTOMATICO;
    Random r = new Random();
    double desviacionEstandar = Consts.DESVIACION_ESTANDAR;
    double media = Consts.MEDIA;
    
    // Distribucion normal
    double duracionIncubacion = r.nextGaussian() * desviacionEstandar + media;
    individuos.get(i).duracionIncubacion = (int) duracionIncubacion;    
    individuos.get(i).tiempoDeContagio = tiempo;
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


/*
  Funcion encargada de simular el numero de contactos basado en el estado actual de 
  los individuos y su nivel de sociabilidad
*/
void simularContactos(){
  contactos = new ArrayList<Contacto>();
  for (int i = 0; i < nIndividuos; i++) {
    Empleado individuoUno = individuos.get(i);
    int contadorContactos = 0;
    
    /*
      El individuo tiene contacto con todos en la empresa un n de veces por hora?
    */
    
    while(contadorContactos < getContactosPorHora(individuoUno.sociabilidad)){
      for (int j = i+1; j < nIndividuos; j++) {      
        Empleado individuoDos = individuos.get(j);      
        float distanciaIndividuos = dist(individuoUno.posX, individuoUno.posY, individuoDos.posX, individuoDos.posY);
        float probabilidadContacto = map((1/distanciaIndividuos), (1/distanciaMax), (1/distanciaMin), 0.0, 1.0);
        float random = (float) Math.random();
        if (random <= probabilidadContacto){
          Random rand = new Random();
          
          // TODO: Revisar que el tiempo maximo en una hora por contacto es 60 mins/ # contactos
          
          // 1 - 60 mins
          int duracionDelContacto = rand.nextInt(Consts.TIEMPO_MAX + 1) + Consts.TIEMPO_MIN;
                    
          //  10 - 150 cms
          int distanciaDelContacto = rand.nextInt(Consts.DIST_MAX_CONTACTO - 9) + Consts.DIST_MIN_CONTACTO;        
          boolean tipoContacto = getTipoDeContacto(individuoUno, individuoDos); //función para determinar si el contacto es efectivo o no
          Contacto nuevoContacto = new Contacto(individuoUno, individuoDos, tipoContacto, duracionDelContacto, distanciaDelContacto);
          contadorContactos++;
          
          // Los individuos en cuarentena salen del sistema
          if(!(individuoUno.estado == Consts.CUARENTENA || individuoDos.estado == Consts.CUARENTENA)){
            contactos.add(nuevoContacto); 
          }               
        }
      }
    }
  }
}

/*
  Funcion que itera sobre los contactos recientes y cambia el estado de los individuos
  involucrados de acuerdo con el tipo de contacto que hubo (efectivo o no)
*/
void simularContagios(){
  for (Contacto contacto : contactos) {
    
    // Si es un contacto efectivo (en el que puede contagiarse uno de los individuos)
    if(contacto.tipo){
      float random = (float) Math.random();
      float factorDuracion = map(contacto.duracion,
                                 Consts.TIEMPO_MIN,
                                 Consts.TIEMPO_MAX,
                                 0.0, 1.0);
      float factorDistancia = map(contacto.distancia,
                                  Consts.DIST_MIN_CONTACTO,
                                  Consts.DIST_MAX_CONTACTO,
                                  1.0, 0.0);
      
      // De donde sale esto?
      float factorSuceptibilidad = (contacto.individuoUno.probContagiar_se + contacto.individuoDos.probContagiar_se)/2;
      float probInfeccion = 0.25*factorDuracion + 0.25*factorDistancia + 0.5*factorSuceptibilidad;
      println("probInfeccion:");
      println(probInfeccion);
      println("random:");
      println(random);
      
      // Se produce un contagio
      if (random <= probInfeccion){
        Random r = new Random();
        double desviacionEstandar = 2;
        double media = 7;
        
        // Distribucion normal
        double duracionIncubacion = r.nextGaussian() * desviacionEstandar + media; 
        if(contacto.individuoUno.estado == Consts.SUSCEPTIBLE){
          contacto.individuoUno.estado = Consts.PRE_SINTOMATICO;
          contacto.individuoUno.tiempoDeContagio = tiempo;
          contacto.individuoUno.duracionIncubacion = (int) duracionIncubacion;
          susceptibles--;
          preSintomaticos++;
        } else if (contacto.individuoDos.estado == Consts.SUSCEPTIBLE){
          contacto.individuoDos.estado = Consts.PRE_SINTOMATICO;
          contacto.individuoDos.tiempoDeContagio = tiempo;
          contacto.individuoDos.duracionIncubacion = (int) duracionIncubacion;
          susceptibles--;
          preSintomaticos++;
        }
      }
    }  
  }
}

/*
  
*/
void evaluarCambiosDeEstado(){
  for (Empleado individuo : individuos) {    
    if (individuo.estado == Consts.PRE_SINTOMATICO){
      if (individuo.tiempoDeContagio + individuo.duracionIncubacion == tiempo){
        float random = (float) Math.random();
        
        // Infectado sintomatico
        if (random <= probSintomatico){          
          individuo.estado = Consts.INF_SINTOMATICO;
          
          //Al inicio de los sintomas los individuos tienen un 50% mayor prob de contagiar
          individuo.probContagiar_se = constrain(individuo.probContagiar_se * 1.5, 0.0, 1.0); 
          preSintomaticos--;
          infectadosSintomaticos++;
        }else{
          
          // Infectado asintomatico
          individuo.estado = Consts.INF_ASINTOMATICO;
          preSintomaticos--;
          infectadosAsintomaticos++;
        }
      }
    }
    
    // Los individuos sintomaticos son puestos en cuarentena al siguiente dia (8 horas despues)
    if (individuo.estado == Consts.INF_SINTOMATICO){
      if (individuo.tiempoDeContagio + individuo.duracionIncubacion + Consts.HORAS_REMISION == tiempo){
        individuo.estado = Consts.CUARENTENA; //En cuarentena
        infectadosSintomaticos--;
        enCuarentena++;
      }
    }
    if (individuo.estado == Consts.INF_ASINTOMATICO){
      if (individuo.tiempoDeContagio + individuo.duracionIncubacion + tiempoDeRecuperacion == tiempo){
        
        // Recuperado asintomatico
        individuo.estado = Consts.REC_ASINTOMATICO; 
        infectadosAsintomaticos--;
        recuperadosAsintomaticos++;
      }
    }
  }  
}

/*
  Funcion que genera con una distribucion de Poisson el numero 
  de contactos que un individuo
  
  @param sociabilidad - El grado de sociabilidad que el individuo tiene
  
  returns numero de contactos
*/
int getContactosPorHora(int sociabilidad){
  int lambda = sociabilidad;
  Random r = new Random();
  double L = Math.exp(-lambda);
  int k = 0;
  double p = 1.0;
  do {
      p = p * r.nextDouble();
      k++;
  } while (p > L);
  return k - 1;
}

/*
  Funcion que determina si el contacto entre dos individuos es efectivo o no
  dependiendo del estado entre los dos.  
  @param individuoUno
  @param individuoDos
  
  returns boolean
*/
boolean getTipoDeContacto(Empleado individuoUno, Empleado individuoDos){
  boolean tipoDeContacto = false;
  int estadoUno = individuoUno.estado;
  int estadoDos = individuoDos.estado;  
  if( (estadoUno == 0 && esInfectado(estadoDos)) || (estadoDos == 0 && esInfectado(estadoUno)) ) {
    tipoDeContacto = true;
  }
  return tipoDeContacto;
}

/*
  Funcion que dado el estado de un individuo, determina si esta infectado o no. 
  @param - estado: Estado de un individuo
  
  returns boolean
*/
private boolean esInfectado(int estado) {
  return estado > Consts.SUSCEPTIBLE && estado < Consts.INF_ASINTOMATICO;
}


/*
  Funcion principal que se encarga de dibujar el nuevo estado de la simulacion 
*/
void dibujar(){
  background(0);
  pushStyle();
  fill(104,151,252);
  textAlign(CENTER);
  textSize(26);
  text("Tiempo: " + floor(tiempo/8) + " Días, " + tiempo%8 + " Hrs", width/2, 25);
  popStyle(); 
  pushStyle();
  fill(104,151,252);
  textAlign(LEFT);
  textSize(20);
  text("Susceptibles: "+ susceptibles, 5+30, 60);
  text("Pre-sintomaticos: "+ preSintomaticos, 110+30, 60);
  text("Infectados sintomaticos: "+ infectadosSintomaticos, 238+30, 60);
  text("Infectados asintomaticos: "+ infectadosAsintomaticos, 403+30, 60);
  text("En cuarentena: "+ enCuarentena, 575+30, 60);
  text("Recuperados: "+ recuperadosAsintomaticos, 685+30, 60);
  popStyle(); 
  pushStyle();
  strokeWeight(3);
  stroke(104,151,252);
  line(85, 85, 85, height-85);
  line(85, 85, width-85, 85);
  line(width-85, height-85, width-85, 85);
  line(85, height-85, width-85, height-85);
  popStyle();
  for (Contacto contacto : contactos) {
    boolean tipoContacto = contacto.tipo;
    color colorArista;
    if(tipoContacto){
      colorArista = color(255, 0, 0);//contacto efectivo - rojo
    }else{
      colorArista = color(0, 0, 255);//contacto no efectivo - azul
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
      case Consts.SUSCEPTIBLE:
               {colorNodo = color(0, 255, 0);
               etiquetaEstado = "S";}
               break;
      case Consts.PRE_SINTOMATICO:
               {colorNodo = color(255, 50, 0);
               etiquetaEstado = "Ip";}
               break;
      case Consts.INF_SINTOMATICO:
               {colorNodo = color(255, 0, 247);
               etiquetaEstado = "Is";}
               break;
      case Consts.INF_ASINTOMATICO:
               {colorNodo = color(141, 30, 131);        
               etiquetaEstado = "Ia";}
               break;
      case Consts.REC_ASINTOMATICO:
               {colorNodo = color(255, 255, 255);        
               etiquetaEstado = "Ra";}
               break;
      case Consts.CUARENTENA:
               {colorNodo = color(220, 255, 0);        
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
