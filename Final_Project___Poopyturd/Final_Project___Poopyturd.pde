import processing.serial.*;
import processing.video.*;


import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.effects.*;
import ddf.minim.signals.*;
import ddf.minim.spi.*;
import ddf.minim.ugens.*;

Minim minim;
AudioPlayer song;

float poopX, poopY;
float time = 0;
int gameScreen = 0;
PImage poop;
PImage swirl;

int wallSpeed = 3;
int wallInterval = 1700;
float lastAddTime = 0;
int minGapHeight = 80;
int maxGapHeight = 200;
int wallWidth = 80;
ArrayList<int[]> walls = new ArrayList<int[]>();

int maxHealth = 100;
float health = 100;
float healthDecrease = 1;
int healthBarWidth = 60;
int speedY = 3;

poop p;
swirl s;

float[] sensorValues = {0};
Serial myPort;

/********* SETUP BLOCK *********/

void setup() {
  size(680, 500);
  frameRate(60);
  poopX = width/4;
  poopY = height/2;
  
  poop = loadImage("poop.png");
  swirl = loadImage("background.png");
  
  printArray(Serial.list());
  
  myPort = new Serial(this, Serial.list()[1], 9600);
  
  myPort.bufferUntil('\n');
  
  minim = new Minim(this);
  song = minim.loadFile("bubble dream.mp3");
}


/********* DRAW BLOCK *********/

void draw() {
  // Display the contents of the current screen
  if (gameScreen == 0) {
    initScreen();
  } else if (gameScreen == 1) {
    gameScreen();
  } else if (gameScreen == 2) {
    gameOverScreen();
  }
}


/********* SCREEN CONTENTS *********/

void initScreen() {
  background(0);
  pushMatrix();
  translate(width/2, height/2);
  stroke(255);
  textSize(48);
  textAlign(CENTER, CENTER);
  text("Press Enter", 0, 0);
  popMatrix();
  
}
void gameScreen() {
  background(255);
  
  s = new swirl();
  s.drawSwirl();
  
  pushMatrix();
  p = new poop();
  p.drawPoop();
  popMatrix();
  
  song.play();
  
  charactercontrol();
  
  wallAdder();
  wallHandler();
  
  drawHealthBar();
  
  if (health <= 0){
    gameOverScreen();
  }
 
  
}
void gameOverScreen() {
  background(0);
  fill(255);
  translate(width/2, height/2);
  textSize(48);
  textAlign(CENTER, CENTER);
  text("GAME OVER", 0, 0);
  
  song.close();
}


/********* INPUTS *********/

void keyPressed(){
  if(key == ENTER) {
    if(gameScreen==0) {
    startGame();
  }
}
}

  void charactercontrol() {
    poopY = map(sensorValues[0], 680, 0, 0, height);
  //if (sensorValues[0] >= 150) {
  //    poopY = poopY - speedY;
  //  } else if (sensorValues[0] <= 100) {
  //    poopY = poopY + speedY;
  //}
}

/********* OTHER FUNCTIONS *********/

// This method sets the necessery variables to start the game  
void startGame() {
  gameScreen=1;
}


void wallAdder() {
  if (millis()-lastAddTime > wallInterval) {
    int randHeight = round(random(minGapHeight, maxGapHeight));
    int randY = round(random(0, height-randHeight));
    // {gapWallX, gapWallY, gapWallWidth, gapWallHeight}
    int[] randWall = {width, randY, wallWidth, randHeight}; 
    walls.add(randWall);
    lastAddTime = millis();
  }
}
void wallHandler() {
  for (int i = 0; i < walls.size(); i++) {
    wallRemover(i);
    wallMover(i);
    wallDrawer(i);
    
    watchWallCollision(i);
  }
}
void wallDrawer(int index) {
  int[] wall = walls.get(index);
  // get gap wall settings 
  int gapWallX = wall[0];
  int gapWallY = wall[1];
  int gapWallWidth = wall[2];
  int gapWallHeight = wall[3];
  // draw actual walls
  rectMode(CORNER);
  //stroke(0);
  strokeWeight(3);
  fill(#9BA6AA);
  rect(gapWallX, 0, gapWallWidth, gapWallY);
  arc(gapWallX - 10, gapWallY + gapWallHeight, gapWallWidth + 4, 100, 0, PI, CHORD);
  rect(gapWallX, gapWallY+gapWallHeight, gapWallWidth, height-(gapWallY+gapWallHeight));
}
void wallMover(int index) {
  int[] wall = walls.get(index);
  wall[0] -= wallSpeed;
}
void wallRemover(int index) {
  int[] wall = walls.get(index);
  if (wall[0]+wall[2] <= 0) {
    walls.remove(index);
  }
}
void decreaseHealth(){
  health -= healthDecrease;
  }

void watchWallCollision(int index) {
  int[] wall = walls.get(index);
  // get gap wall settings 
  int gapWallX = wall[0];
  int gapWallY = wall[1];
  int gapWallWidth = wall[2];
  int gapWallHeight = wall[3];
  int wallTopX = gapWallX;
  int wallTopY = 0;
  int wallTopWidth = gapWallWidth;
  int wallTopHeight = gapWallY;
  int wallBottomX = gapWallX;
  int wallBottomY = gapWallY+gapWallHeight;
  int wallBottomWidth = gapWallWidth;
  int wallBottomHeight = height-(gapWallY+gapWallHeight);

  if (
    (poopX >= wallTopX) &&
    (poopX <= wallTopX+wallTopWidth) &&
    (poopY >= wallTopY) &&
    (poopY <= wallTopY+wallTopHeight)
    ) {
    decreaseHealth();
  }
  
  if (
    (poopX >= wallBottomX) &&
    (poopX <= wallBottomX+wallBottomWidth) &&
    (poopY >= wallBottomY) &&
    (poopY <= wallBottomY+wallBottomHeight)
    ) {
    decreaseHealth();
  }
}

void drawHealthBar() {
  noStroke();
  fill(236, 240, 241);
  rectMode(CORNER);
  rect(poopX -(healthBarWidth/2), poopY - 30, healthBarWidth, 5);
  if (health > 60) {
    fill(46, 204, 113);
  } else if (health > 30) {
    fill(230, 126, 34);
  } else {
    fill(231, 76, 60);
  }
  rectMode(CORNER);
  rect(poopX -(healthBarWidth/2), poopY - 30, healthBarWidth *(health/maxHealth), 5);
}

void serialEvent(Serial myPort) { 
  String inString = myPort.readStringUntil('\n'); 
  if (inString != null) {
    inString = trim(inString); 
    sensorValues[0] = int(inString);
  }
    println(sensorValues);
}