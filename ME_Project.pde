import java.lang.Math;
import java.util.Random;
import java.util.*;

int nIndividuos;
int tiempo;
List<Contacto> contactos = new ArrayList<Contacto>();
List<Empleado> individuos = new ArrayList<Empleado>();
float distanciaMax,distanciaMin;//distancias entre individuos
float probSintomatico;//probabibilidad de que un individuo sea sintomatico
int tiempoDeRecuperacion; 
int nInicialDeInfectados;
int susceptibles, preSintomaticos, infectadosSintomaticos, infectadosAsintomaticos, recuperadosAsintomaticos, enCuarentena =  0;

float X1, Y1;
float X2, Y2;

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
  nIndividuos = 25;
  nInicialDeInfectados = 2;
  susceptibles = nIndividuos - nInicialDeInfectados;
  preSintomaticos = nInicialDeInfectados;
  probSintomatico = 0.7;
  tiempoDeRecuperacion = 14;
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
    float random = (float) Math.random();//las posiciones de cada empleado son aleatorias
    float posX = map(random, 0.0, 1.0, X1, X2);
    random = (float) Math.random();
    float posY = map(random, 0.0, 1.0, Y1, Y2);  
    Random rand = new Random();
    int estado = 0; //todos los individuos menos el numero de infectados inicial comienzan como susceptibles
    int sociabilidad = rand.nextInt(3); //determina el numero de contactos por hora de cada individuo
    float probContagiar_se = (float) Math.random(); //probabilidad de contagiar o de contagiarse 
    Empleado nuevoIndividuo = new Empleado(i, estado, posX, posY, -1, -1, probContagiar_se, sociabilidad);
    individuos.add(nuevoIndividuo);
  }
  for (int i = 0; i < nInicialDeInfectados; i++) {//se cambia el estado de los infectados iniciales   
    individuos.get(i).estado = 1;
    Random r = new Random();
    double desviacionEstandar = 2;
    double media = 7;
    double duracionIncubacion = r.nextGaussian()*desviacionEstandar+media; //distribución normal
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

void simularContactos(){
  contactos = new ArrayList<Contacto>();
  for (int i = 0; i < nIndividuos; i++) {
    Empleado individuoUno = individuos.get(i);
    int contadorContactos = 0;
    while(contadorContactos < getContactosPorHora(individuoUno.sociabilidad)){
      for (int j = i+1; j < nIndividuos; j++) {      
        Empleado individuoDos = individuos.get(j);      
        float distanciaIndividuos = dist(individuoUno.posX, individuoUno.posY, individuoDos.posX, individuoDos.posY);
        float probabilidadContacto = map((1/distanciaIndividuos), (1/distanciaMax), (1/distanciaMin), 0.0, 1.0);
        float random = (float) Math.random();
        if (random <= probabilidadContacto){
          Random rand = new Random();
          int duracionDelContacto = rand.nextInt(61) + 1; // 1 - 60 mins 
          int distanciaDelContacto = rand.nextInt(141) + 10; // 10 - 150 cms 
          boolean tipoContacto = getTipoDeContacto(individuoUno, individuoDos); //función para determinar si el contacto es efectivo o no
          Contacto nuevoContacto = new Contacto(individuoUno, individuoDos, tipoContacto, duracionDelContacto, distanciaDelContacto);
          contadorContactos++;
          if(!(individuoUno.estado == 5 || individuoDos.estado == 5)){//los individuos en cuarentena salen del sistema
            contactos.add(nuevoContacto); 
          }               
        }
      }
    }
  }
}

void simularContagios(){
  for (Contacto contacto : contactos) {
    if(contacto.tipo){//si es un contacto efectivo (en el que puede contagiarse alguno de los dos individuos)
      float random = (float) Math.random();
      float factorDuracion = map(contacto.duracion,1,60,0.0,1.0);
      float factorDistancia = map(contacto.distancia,10,150,1.0,0.0);
      float factorSuceptibilidad = (contacto.individuoUno.probContagiar_se + contacto.individuoDos.probContagiar_se)/2;
      float probInfeccion = 0.25*factorDuracion + 0.25*factorDistancia + 0.5*factorSuceptibilidad;
      println("probInfeccion:");
      println(probInfeccion);
      println("random:");
      println(random);
      if (random <= probInfeccion){//se produce un contagio
        Random r = new Random();
        double desviacionEstandar = 2;
        double media = 7;
        double duracionIncubacion = r.nextGaussian()*desviacionEstandar+media; //distribución normal 
        if(contacto.individuoUno.estado == 0){
          contacto.individuoUno.estado = 1;
          contacto.individuoUno.tiempoDeContagio = tiempo;
          contacto.individuoUno.duracionIncubacion = (int) duracionIncubacion;
          susceptibles--;
          preSintomaticos++;
        }else if(contacto.individuoDos.estado == 0){
          contacto.individuoDos.estado = 1;
          contacto.individuoDos.tiempoDeContagio = tiempo;
          contacto.individuoDos.duracionIncubacion = (int) duracionIncubacion;
          susceptibles--;
          preSintomaticos++;
        }
      }
    }  
  }
}

void evaluarCambiosDeEstado(){
  for (Empleado individuo : individuos) {    
    if (individuo.estado == 1){
      if (individuo.tiempoDeContagio + individuo.duracionIncubacion == tiempo){
        float random = (float) Math.random();
        if (random <= probSintomatico){
          individuo.estado = 2;//Infectado sintomatico
          individuo.probContagiar_se = constrain(individuo.probContagiar_se*1.5,0.0,1.0); //Al inicio de los sintomas los individuos tienen un 50% mayor prob de contagiar
          preSintomaticos--;
          infectadosSintomaticos++;
        }else{
          individuo.estado = 3;//Infectado asintomatico
          preSintomaticos--;
          infectadosAsintomaticos++;
        }
      }
    }    
    if (individuo.estado == 2){//Los individuos sintomaticos son puestos en cuarentena al siguiente dia (8 horas despues)
      if (individuo.tiempoDeContagio + individuo.duracionIncubacion + 8 == tiempo){
        individuo.estado = 5; //En cuarentena
        infectadosSintomaticos--;
        enCuarentena++;
      }
    }
    if (individuo.estado == 3){
      if (individuo.tiempoDeContagio + individuo.duracionIncubacion + tiempoDeRecuperacion == tiempo){
        individuo.estado = 4; //Recuperado asintomatico
        infectadosAsintomaticos--;
        recuperadosAsintomaticos++;
      }
    }
  }  
}

int getContactosPorHora(int sociabilidad){ //generador para una distribución de poisson para el numero de contactos por hora de cada empleado
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

boolean getTipoDeContacto(Empleado individuoUno, Empleado individuoDos){
  boolean tipoDeContacto;
  if((individuoUno.estado == 0 || individuoDos.estado == 0) && ( ((individuoUno.estado == 1 || individuoDos.estado == 1)) 
      || ((individuoUno.estado == 2 || individuoDos.estado == 2)) || ((individuoUno.estado == 3 || individuoDos.estado == 3)) )){
     tipoDeContacto = true; 
  }
  else{
    tipoDeContacto = false;
  }
  return tipoDeContacto;
}

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
