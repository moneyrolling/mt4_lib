//+------------------------------------------------------------------+
//|                               SAMPLE CODE FOR USING MQ4  LIB.mq5 |
//|                                   Copyright 2018, Money Rolling. |
//|                                      http://www.moneyrolling.top |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Money Rolling."
#property link      "http://www.moneyrolling.top"
#property version   "1.00"

#include <mt4_lib.mqh>   //<------------ INCLUDE DURING THE LIBRARY HERE------------->

MT4_Lib mt4;             //<------------ START CREATING A NEW CLASS------------->

//// EA PARAMETER ///
extern int EA_Magic = 88729;
//// TRAINING PARAMETER ////


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   // INITIALIZATION FOR MT4_LIB.MQH
   mt4.setPeriod(_Period);    //<------------ SET THE EA PARAMETER------------->
   mt4.setSymbol(_Symbol);
   mt4.setMagic(EA_Magic);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
     print_example_function (0,100);
     
     //+---------------------OUTCOME EXAMPLE---------------------+
     //|----This is the highest candle since 2017.08.31 20.22----|
     //+---------------------------------------------------------+
  }
  
bool check_highest (int input_bar, int count)  //input bar and how many total candles to be count (count to the left)
{
   double Highest = mt4.iHighestPrice(input_bar,count);
   double Lowest  = mt4.iLowestPrice(input_bar,count);
   double Open    = mt4.Open(input_bar);
   double Close   = mt4.Close(input_bar);
   double High    = mt4.High(input_bar);
   double Low     = mt4.Low(input_bar);
   
   //example function
   
   if (Open> Close) //bull candle
   {
      if (High>Highest) //this is the highest candle among the previous candle
      {
         return (true);
      }
   }
 return(false);
}

void print_example_function (int input_bar, int count)
{
   datetime time;  
   
   if (check_highest(input_bar,count))
   {
       time=mt4.iTime(100); // time of the current bar
       Print ("This is the highest candle since "+time);
   }
}





//+------------------------------------------------------------------+

