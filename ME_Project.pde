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


int nIndividuos;
int tiempo;
List<Contacto> contactos = new ArrayList<Contacto>();
List<Empleado> individuos = new ArrayList<Empleado>();
Consts constantes = new Consts();

// Distancia entre individuos
float distanciaMax,distanciaMin;

// Probabilidad de que un individuo sea sintomatico
float probSintomatico;
// Probabilidad de recuperacion para un individuo sintomatico
float probRecuperacion;
// Tiempo de recuperacion para un individuo sintomatico
int tiempoDeRecuperacion; 
int nInicialDeInfectados;
int sociabilidadMaxima;

// Variables que contienen el numero de individuos en las diferentes etapas
// de la infeccion
int susceptibles, preSintomaticos, infectadosSintomaticos, infectadosAsintomaticos, recuperados, enCuarentena, muertos =  0;

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
  probRecuperacion = Consts.PROBABILIDAD_RECUPERACION;
  tiempoDeRecuperacion = Consts.TIEMPO_RECUPERACION;
  sociabilidadMaxima = Consts.SOCIABILIDAD_MAX;
  susceptibles = nIndividuos - nInicialDeInfectados;
  generarNodos();
}

/*
  Funcion encargada de dibujar cuadro a cuadro el nuevo estado de los
  individuos.
  Cada 3 segundos actualiza el estado de los individuos.
*/

void draw(){
  if(frameCount == 1){
    dibujar();
  }
  if(frameCount%3==0){ 
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
    
    // Determina el numero de contactos por dia de cada individuo
    int sociabilidad = rand.nextInt(sociabilidadMaxima);
    
    // La probabilidad de contagiar o ser contagiado
    float probContagiar_se = (float) Math.random(); 
    Empleado nuevoIndividuo = new Empleado(i, estado, posX, posY, -1, -1, probContagiar_se, sociabilidad,-1);
    individuos.add(nuevoIndividuo);
  }
  
  // Se cambia el estado de los infectados iniciales
  for (int i = 0; i < nInicialDeInfectados; i++) {   
    individuos.get(i).setEstado(Consts.PRE_SINTOMATICO);
    Random r = new Random();
    double desviacionEstandar = Consts.DESVIACION_ESTANDAR;
    double media = Consts.MEDIA;
    
    // Distribucion normal para la duracion del periodo de incubacion
    double duracionIncubacion = r.nextGaussian() * desviacionEstandar + media;
    individuos.get(i).duracionIncubacion = (int) duracionIncubacion;    
    individuos.get(i).tiempoDeContagio = tiempo;
  }
  //se calculan las distancias maxima y minima entre todos los individuos para usarlas mas adelante
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
  los individuos y su grado de sociabilidad
*/
void simularContactos(){
  contactos = new ArrayList<Contacto>();
  
  for (int i = 0; i < nIndividuos; i++){
    Empleado individuoUno = individuos.get(i);
    int contadorContactosIndividuo = 0;
    ArrayList<Boolean> individuosHayContacto = new ArrayList<Boolean>();
    
    for (int k = 0; k < nIndividuos; k++){individuosHayContacto.add(false);}//arreglo auxiliar para que los contactos sean con individuos diferentes
    //Por cada individuo se generan experimentos hasta que el numero de contactos generados por ese individuo sea igual al numero de contactos por dia establecido
    //la sociabilidad se obtiene de una distribucion de poisson con media igual al grado de sociabilidad del individuo
    int contactosDia = getContactosPorDia(individuoUno.sociabilidad);
    
    while(contadorContactosIndividuo < contactosDia){
      
      for (int j = 0; j < nIndividuos; j++) {
        
        if((!individuosHayContacto.get(j)) && (i!=j)){//el numero de contactos debe ser con individuos diferentes
          Empleado individuoDos = individuos.get(j);   
          float distanciaIndividuos = dist(individuoUno.posX, individuoUno.posY, individuoDos.posX, individuoDos.posY);
          //la probabilidad de contacto es inversamente proporcional a la distancia entre individuos
          float probabilidadContacto = map((1/distanciaIndividuos), (1/distanciaMax), (1/distanciaMin), 0.0, 1.0);
          float random = (float) Math.random();
          
          if (random <= probabilidadContacto){
            // Los individuos en cuarentena o muertos salen del sistema, no puede haber contacto con individuos en estos estados
            if( (!individuoUno.enCuarentena()) && (!individuoDos.enCuarentena()) && (!individuoUno.fallecio()) && (!individuoDos.fallecio()) ){
              //se crea el contacto entre los dos individuos
              // 1 - 240 mins
              Random rand = new Random();
              int duracionDelContacto = rand.nextInt(Consts.TIEMPO_MAX) + Consts.TIEMPO_MIN;                      
              //  10 - 150 cms
              int distanciaDelContacto = rand.nextInt(Consts.DIST_MAX_CONTACTO - Consts.DIST_MIN_CONTACTO + 1) + Consts.DIST_MIN_CONTACTO;        
              boolean tipoContacto = getTipoDeContacto(individuoUno, individuoDos); //función para determinar si el contacto es efectivo o no
              Contacto nuevoContacto = new Contacto(individuoUno, individuoDos, tipoContacto, duracionDelContacto, distanciaDelContacto);
              contactos.add(nuevoContacto);
            } 
            contadorContactosIndividuo++;
            individuosHayContacto.set(j,true);
          }
        }
        if(contadorContactosIndividuo == contactosDia){
          break;//se termina el ciclo cuando ya se ha completado el numero de contactos por dia para cada empleado
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
      float factorDuracion = map(contacto.duracion, // se mapea la duracion del contacto a un valor de prob
                                 Consts.TIEMPO_MIN,
                                 Consts.TIEMPO_MAX,
                                 0.0, 1.0);
      float factorDistancia = map(contacto.distancia, // se mapea la distancia a la que se dio el contacto a un valor de prob
                                  Consts.DIST_MIN_CONTACTO,
                                  Consts.DIST_MAX_CONTACTO,
                                  1.0, 0.0);
      
      float factorSuceptibilidad = (contacto.individuoUno.probContagiar_se + contacto.individuoDos.probContagiar_se)/2;
      float probInfeccion = 0.25*factorDuracion + 0.25*factorDistancia + 0.5*factorSuceptibilidad;
      println("probInfeccion:");
      println(probInfeccion);
      println("random:");
      println(random);
      
      // Se produce un contagio
      if (random <= probInfeccion){
        Random r = new Random();
        double desviacionEstandar = Consts.DESVIACION_ESTANDAR;
        double media = Consts.MEDIA;
        
        // Distribucion normal
        double duracionIncubacion = r.nextGaussian() * desviacionEstandar + media; 
        if(contacto.individuoUno.esSusceptible()){
          contacto.individuoUno.setEstado(Consts.PRE_SINTOMATICO);
          contacto.individuoUno.tiempoDeContagio = tiempo;
          contacto.individuoUno.duracionIncubacion = (int) duracionIncubacion;
          susceptibles--;
          preSintomaticos++;
        } else if (contacto.individuoDos.esSusceptible()){
          contacto.individuoDos.setEstado(Consts.PRE_SINTOMATICO);
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
    
    if (individuo.esPreSintomatico()){
      if (individuo.tiempoDeContagio + individuo.duracionIncubacion == tiempo){
        float random = (float) Math.random();
        
        // Infectado sintomatico
        if (random <= probSintomatico){          
          individuo.setEstado(Consts.INF_SINTOMATICO);
          
          //Al inicio de los sintomas los individuos tienen un 50% mayor prob de contagiar
          individuo.probContagiar_se = constrain(individuo.probContagiar_se * 1.5, 0.0, 1.0); 
          Random rand = new Random();
                  
          // 14 - 45 dias
          int duracionEnfermedad = rand.nextInt(Consts.DURACION_MAX_ENFERMEDAD - Consts.DURACION_MIN_ENFERMEDAD) + Consts.DURACION_MIN_ENFERMEDAD;
          individuo.duracionEnfermedad = duracionEnfermedad;
          preSintomaticos--;
          infectadosSintomaticos++;
        }else{
          
          // Infectado asintomatico
          individuo.setEstado(Consts.INF_ASINTOMATICO);
          preSintomaticos--;
          infectadosAsintomaticos++;
        }
      }
    }
    
    // Los individuos sintomaticos son puestos en cuarentena un día despues del inicio de los sintomas
    if (individuo.esInfSintomatico()){
      if (individuo.tiempoDeContagio + individuo.duracionIncubacion + Consts.DIAS_REMISION == tiempo){
        individuo.setEstado(Consts.CUARENTENA); //En cuarentena
        infectadosSintomaticos--;
        enCuarentena++;
      }
    }
    if (individuo.esInfAsintomatico()){
      if (individuo.tiempoDeContagio + individuo.duracionIncubacion + Consts.TIEMPO_RECUPERACION == tiempo){
        
        // Recuperado asintomatico
        individuo.setEstado(Consts.REC_ASINTOMATICO); 
        infectadosAsintomaticos--;
        recuperados++;
      }
    }
    if (individuo.enCuarentena()){
      if (individuo.tiempoDeContagio + individuo.duracionIncubacion + individuo.duracionEnfermedad == tiempo){
        float random = (float) Math.random();
        if (random <= probRecuperacion){
          
          // Recuperado sintomatico
          individuo.setEstado(Consts.REC_SINTOMATICO); 
          enCuarentena--;
          recuperados++;
          }
        else{
          individuo.setEstado(Consts.MUERTO);
          muertos++;
          enCuarentena--;
          }          
        }      
      }
    }
}

/*
  Funcion que genera con una distribucion de Poisson el numero 
  de contactos que un individuo
  
  Algoritmo para generar varibles con poisson computacionalmente eficiente
  https://en.wikipedia.org/wiki/Poisson_distribution#Generating_Poisson-distributed_random_variables
  
  @param sociabilidad - El grado de sociabilidad que el individuo tiene
  
  returns numero de contactos
*/
int getContactosPorDia(int sociabilidad){
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
  if( (individuoUno.esSusceptible() && individuoDos.esInfectado()) ||
      (individuoDos.esSusceptible() && individuoUno.esInfectado()) ) {
    tipoDeContacto = true;
  }
  return tipoDeContacto;
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
  text("Tiempo: " + tiempo + " Días", width/2, 25);
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
  text("Recuperados: "+ recuperados, 685+30, 60);
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
    switch (individuo.getEstado()) {
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
      case Consts.REC_SINTOMATICO:
               {colorNodo = color(0, 255, 162);        
               etiquetaEstado = "Rs";}
               break;
      case Consts.MUERTO:
               {colorNodo = color(255, 0, 0);        
               etiquetaEstado = "M";}
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
