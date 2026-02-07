//+------------------------------------------------------------------+
//|                                                   MT_MANAGER.mq5 |
//|                                    MT_MANAGER by nwf - MT5 Tool  |
//|              Manage TP & SL for all positions on current pair    |
//+------------------------------------------------------------------+
#property copyright "MT_MANAGER by nwf"
#property link      ""
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>

//--- Input parameters
input double TargetTP = 0.0;  // Target Take Profit Default (harga)
input double TargetSL = 0.0;  // Target Stop Loss Default (harga)

//--- Auto Close at Time
input group "=== AUTO CLOSE AT TIME ==="
input bool EnableAutoClose = false;           // Enable Auto Close (default: OFF)
input string AutoCloseTime = "23:00";         // Close Time (HH:MM)

//--- Auto Entry After Weekend
input group "=== AUTO ENTRY AFTER WEEKEND ==="
input bool EnableAutoEntry = false;           // Enable Auto Entry (default: OFF)
input ENUM_ORDER_TYPE EntryType = ORDER_TYPE_BUY;  // Entry Type (BUY/SELL)
input double EntryPrice = 0.0;                // Entry Price
input double EntryLot = 0.01;                 // Lot Size
input int EntryTPPips = 30;                   // TP in Pips
input int EntrySLPips = 20;                   // SL in Pips

//--- Global variables
CTrade trade;
string currentSymbol;
double CurrentTargetTP = 0.0;  // Current working TP (modifiable)
double CurrentTargetSL = 0.0;  // Current working SL (modifiable)
int totalPositions = 0;
double totalLots = 0.0;
double estimatedProfit = 0.0;
double estimatedLoss = 0.0;
double totalProfitPips = 0.0;   // Total profit in pips
double totalLossPips = 0.0;      // Total loss in pips

//--- Auto Entry variables
bool marketJustOpened = false;
bool entryExecuted = false;
datetime lastCheckTime = 0;

//--- UI Object names
#define BTN_SET_TP "BtnSetTP"
#define BTN_SET_SL "BtnSetSL"
#define BTN_CLOSE_ALL "BtnCloseAll"
#define EDIT_TP_INPUT "EditTPInput"
#define EDIT_SL_INPUT "EditSLInput"
#define LABEL_TP_PROMPT "LabelTPPrompt"
#define LABEL_SL_PROMPT "LabelSLPrompt"
#define LABEL_HEADER "LabelHeader"
#define LABEL_SYMBOL "LabelSymbol"
#define LABEL_SPREAD "LabelSpread"
#define LABEL_TIMEFRAME "LabelTimeframe"
#define LABEL_COUNTDOWN "LabelCountdown"
#define LABEL_MARKET_CLOSE "LabelMarketClose"
#define LABEL_TARGET_TP "LabelTargetTP"
#define LABEL_TARGET_SL "LabelTargetSL"
#define LABEL_POSITIONS "LabelPositions"
#define LABEL_LOTS "LabelLots"
#define LABEL_PROFIT "LabelProfit"
#define LABEL_LOSS "LabelLoss"
#define LABEL_PROFIT_PIPS "LabelProfitPips"
#define LABEL_LOSS_PIPS "LabelLossPips"

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   currentSymbol = _Symbol;
   
   //--- Initialize from input parameters
   CurrentTargetTP = TargetTP;
   CurrentTargetSL = TargetSL;
   
   //--- Auto-detect TP/SL from existing positions if not set
   if(CurrentTargetTP == 0.0 || CurrentTargetSL == 0.0)
   {
      DetectTPSLFromPositions();
   }
   
   //--- Create UI elements
   CreateButtons();
   CreatePanel();
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   //--- Remove all objects
   ObjectDelete(0, BTN_SET_TP);
   ObjectDelete(0, BTN_SET_SL);
   ObjectDelete(0, BTN_CLOSE_ALL);
   ObjectDelete(0, EDIT_TP_INPUT);
   ObjectDelete(0, EDIT_SL_INPUT);
   ObjectDelete(0, LABEL_TP_PROMPT);
   ObjectDelete(0, LABEL_SL_PROMPT);
    ObjectDelete(0, LABEL_HEADER);
    ObjectDelete(0, LABEL_SYMBOL);
    ObjectDelete(0, LABEL_SPREAD);
    ObjectDelete(0, LABEL_TIMEFRAME);
   ObjectDelete(0, LABEL_COUNTDOWN);
   ObjectDelete(0, LABEL_MARKET_CLOSE);
   ObjectDelete(0, LABEL_TARGET_TP);
   ObjectDelete(0, LABEL_TARGET_SL);
   ObjectDelete(0, LABEL_POSITIONS);
   ObjectDelete(0, LABEL_LOTS);
   ObjectDelete(0, LABEL_PROFIT);
   ObjectDelete(0, LABEL_LOSS);
   ObjectDelete(0, LABEL_PROFIT_PIPS);
   ObjectDelete(0, LABEL_LOSS_PIPS);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   //--- Calculate position data
   CalculatePositionData();
   
   //--- Update display
   UpdateDisplay();
   
   //--- Modify TP if CurrentTargetTP is set
   if(CurrentTargetTP > 0)
   {
      ModifyAllPositionsTP();
   }
   
   //--- Modify SL if CurrentTargetSL is set
   if(CurrentTargetSL > 0)
   {
      ModifyAllPositionsSL();
   }
   
   //--- Auto Close at Time
   if(EnableAutoClose)
   {
      CheckAutoClose();
   }
   
   //--- Auto Entry After Weekend
   if(EnableAutoEntry)
   {
      CheckAutoEntry();
   }
}

//+------------------------------------------------------------------+
//| Chart event function                                             |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
   //--- Handle button clicks
   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      if(sparam == BTN_SET_TP)
      {
         //--- Set TP button clicked
         ObjectSetInteger(0, BTN_SET_TP, OBJPROP_STATE, false);
         
         //--- Read value from input box
         string inputText = ObjectGetString(0, EDIT_TP_INPUT, OBJPROP_TEXT);
         double inputTP = StringToDouble(inputText);
         
         if(inputTP > 0)
         {
            CurrentTargetTP = inputTP;
            ModifyAllPositionsTP();
            Print("TP telah diset ke: ", CurrentTargetTP);
         }
         else
         {
            Print("Masukkan harga TP yang valid di input box");
         }
      }
      else if(sparam == BTN_SET_SL)
      {
         //--- Set SL button clicked
         ObjectSetInteger(0, BTN_SET_SL, OBJPROP_STATE, false);
         
         //--- Read value from input box
         string inputText = ObjectGetString(0, EDIT_SL_INPUT, OBJPROP_TEXT);
         double inputSL = StringToDouble(inputText);
         
         if(inputSL > 0)
         {
            CurrentTargetSL = inputSL;
            ModifyAllPositionsSL();
            Print("SL telah diset ke: ", CurrentTargetSL);
         }
         else
         {
            Print("Masukkan harga SL yang valid di input box");
         }
      }
      else if(sparam == BTN_CLOSE_ALL)
      {
         //--- Close All button clicked
         ObjectSetInteger(0, BTN_CLOSE_ALL, OBJPROP_STATE, false);
         
         CloseAllPositions();
      }
   }
   
   //--- Handle edit box changes
   if(id == CHARTEVENT_OBJECT_ENDEDIT)
   {
      if(sparam == EDIT_TP_INPUT)
      {
         //--- User pressed Enter in TP edit box
         string inputText = ObjectGetString(0, EDIT_TP_INPUT, OBJPROP_TEXT);
         double inputTP = StringToDouble(inputText);
         
         if(inputTP > 0)
         {
            CurrentTargetTP = inputTP;
            ModifyAllPositionsTP();
            Print("TP telah diset ke: ", CurrentTargetTP, " (via Enter)");
         }
      }
      else if(sparam == EDIT_SL_INPUT)
      {
         //--- User pressed Enter in SL edit box
         string inputText = ObjectGetString(0, EDIT_SL_INPUT, OBJPROP_TEXT);
         double inputSL = StringToDouble(inputText);
         
         if(inputSL > 0)
         {
            CurrentTargetSL = inputSL;
            ModifyAllPositionsSL();
            Print("SL telah diset ke: ", CurrentTargetSL, " (via Enter)");
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Calculate position data                                          |
//+------------------------------------------------------------------+
void CalculatePositionData()
{
   totalPositions = 0;
   totalLots = 0.0;
   estimatedProfit = 0.0;
   estimatedLoss = 0.0;
   totalProfitPips = 0.0;
   totalLossPips = 0.0;
   
   //--- Get symbol info
   double point = SymbolInfoDouble(currentSymbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(currentSymbol, SYMBOL_DIGITS);
   
   //--- Loop through all positions
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0)
      {
         if(PositionGetString(POSITION_SYMBOL) == currentSymbol)
         {
            totalPositions++;
            
            double posLots = PositionGetDouble(POSITION_VOLUME);
            double posOpenPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            
            totalLots += posLots;
            
            double tickValue = SymbolInfoDouble(currentSymbol, SYMBOL_TRADE_TICK_VALUE);
            
            //--- Calculate estimated profit if CurrentTargetTP is reached
            if(CurrentTargetTP > 0)
            {
               double profitPoints = 0.0;
               
               if(posType == POSITION_TYPE_BUY)
               {
                  profitPoints = (CurrentTargetTP - posOpenPrice) / point;
               }
               else if(posType == POSITION_TYPE_SELL)
               {
                  profitPoints = (posOpenPrice - CurrentTargetTP) / point;
               }
               
               double profit = profitPoints * tickValue * posLots;
               estimatedProfit += profit;
               totalProfitPips += profitPoints / 10;  // Convert to pips
            }
            
            //--- Calculate estimated loss if CurrentTargetSL is reached
            if(CurrentTargetSL > 0)
            {
               double lossPoints = 0.0;
               
               if(posType == POSITION_TYPE_BUY)
               {
                  lossPoints = (CurrentTargetSL - posOpenPrice) / point;
               }
               else if(posType == POSITION_TYPE_SELL)
               {
                  lossPoints = (posOpenPrice - CurrentTargetSL) / point;
               }
               
               double loss = lossPoints * tickValue * posLots;
               estimatedLoss += loss;
               totalLossPips += lossPoints / 10;  // Convert to pips
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Detect TP/SL from existing positions                             |
//+------------------------------------------------------------------+
void DetectTPSLFromPositions()
{
   double detectedTP = 0.0;
   double detectedSL = 0.0;
   int posCount = 0;
   
   //--- Loop through all positions to find common TP/SL
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0)
      {
         if(PositionGetString(POSITION_SYMBOL) == currentSymbol)
         {
            double posTP = PositionGetDouble(POSITION_TP);
            double posSL = PositionGetDouble(POSITION_SL);
            
            //--- If this is the first position, use its TP/SL
            if(posCount == 0)
            {
               detectedTP = posTP;
               detectedSL = posSL;
            }
            else
            {
               //--- Check if all positions have the same TP/SL
               int digits = (int)SymbolInfoInteger(currentSymbol, SYMBOL_DIGITS);
               if(MathAbs(NormalizeDouble(detectedTP, digits) - NormalizeDouble(posTP, digits)) > 0.00001)
               {
                  detectedTP = 0.0; // Different TPs, don't auto-set
               }
               if(MathAbs(NormalizeDouble(detectedSL, digits) - NormalizeDouble(posSL, digits)) > 0.00001)
               {
                  detectedSL = 0.0; // Different SLs, don't auto-set
               }
            }
            
            posCount++;
         }
      }
   }
   
   //--- Set detected values if found and not already set by input parameter
   if(CurrentTargetTP == 0.0 && detectedTP > 0.0)
   {
      CurrentTargetTP = detectedTP;
      Print("TP terdeteksi dari posisi: ", CurrentTargetTP);
   }
   
   if(CurrentTargetSL == 0.0 && detectedSL > 0.0)
   {
      CurrentTargetSL = detectedSL;
      Print("SL terdeteksi dari posisi: ", CurrentTargetSL);
   }
}

//+------------------------------------------------------------------+
//| Modify TP of all positions                                       |
//+------------------------------------------------------------------+
void ModifyAllPositionsTP()
{
   if(CurrentTargetTP <= 0)
      return;
   
   int modifiedCount = 0;
   
   //--- Loop through all positions
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0)
      {
         if(PositionGetString(POSITION_SYMBOL) == currentSymbol)
         {
            double currentTP = PositionGetDouble(POSITION_TP);
            double currentSL = PositionGetDouble(POSITION_SL);
            
            //--- Normalize CurrentTargetTP
            int digits = (int)SymbolInfoInteger(currentSymbol, SYMBOL_DIGITS);
            double normalizedTargetTP = NormalizeDouble(CurrentTargetTP, digits);
            double normalizedCurrentTP = NormalizeDouble(currentTP, digits);
            
            //--- Only modify if TP is different
            if(normalizedCurrentTP != normalizedTargetTP)
            {
               if(trade.PositionModify(ticket, currentSL, normalizedTargetTP))
               {
                  modifiedCount++;
               }
               else
               {
                  Print("Error modifying TP position #", ticket, ": ", trade.ResultRetcodeDescription());
               }
            }
         }
      }
   }
   
   if(modifiedCount > 0)
   {
      Print(modifiedCount, " posisi berhasil diubah TP-nya ke: ", CurrentTargetTP);
   }
}

//+------------------------------------------------------------------+
//| Modify SL of all positions                                       |
//+------------------------------------------------------------------+
void ModifyAllPositionsSL()
{
   if(CurrentTargetSL <= 0)
      return;
   
   int modifiedCount = 0;
   
   //--- Loop through all positions
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0)
      {
         if(PositionGetString(POSITION_SYMBOL) == currentSymbol)
         {
            double currentTP = PositionGetDouble(POSITION_TP);
            double currentSL = PositionGetDouble(POSITION_SL);
            
            //--- Normalize CurrentTargetSL
            int digits = (int)SymbolInfoInteger(currentSymbol, SYMBOL_DIGITS);
            double normalizedTargetSL = NormalizeDouble(CurrentTargetSL, digits);
            double normalizedCurrentSL = NormalizeDouble(currentSL, digits);
            
            //--- Only modify if SL is different
            if(normalizedCurrentSL != normalizedTargetSL)
            {
               if(trade.PositionModify(ticket, normalizedTargetSL, currentTP))
               {
                  modifiedCount++;
               }
               else
               {
                  Print("Error modifying SL position #", ticket, ": ", trade.ResultRetcodeDescription());
               }
            }
         }
      }
   }
   
   if(modifiedCount > 0)
   {
      Print(modifiedCount, " posisi berhasil diubah SL-nya ke: ", CurrentTargetSL);
   }
}

//+------------------------------------------------------------------+
//| Close all positions                                              |
//+------------------------------------------------------------------+
void CloseAllPositions()
{
   int closedCount = 0;
   
   //--- Loop through all positions
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0)
      {
         if(PositionGetString(POSITION_SYMBOL) == currentSymbol)
         {
            if(trade.PositionClose(ticket))
            {
               closedCount++;
            }
            else
            {
               Print("Error closing position #", ticket, ": ", trade.ResultRetcodeDescription());
            }
         }
      }
   }
   
   Print(closedCount, " posisi berhasil ditutup");
}

//+------------------------------------------------------------------+
//| Update display information                                       |
//+------------------------------------------------------------------+
void UpdateDisplay()
{
   //--- Update panel labels
   UpdatePanelLabels();
}

//+------------------------------------------------------------------+
//| Create buttons                                                    |
//+------------------------------------------------------------------+
void CreateButtons()
{
   int x = 10;
   int y = 30;
   int width = 180;
   int height = 35;
   int spacing = 8;
   int currentY = y;
   
   //--- Label: TP Input Prompt
   if(ObjectFind(0, LABEL_TP_PROMPT) < 0)
   {
      ObjectCreate(0, LABEL_TP_PROMPT, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, LABEL_TP_PROMPT, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, LABEL_TP_PROMPT, OBJPROP_YDISTANCE, currentY);
      ObjectSetString(0, LABEL_TP_PROMPT, OBJPROP_TEXT, "Input Target TP:");
      ObjectSetInteger(0, LABEL_TP_PROMPT, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(0, LABEL_TP_PROMPT, OBJPROP_FONTSIZE, 9);
      ObjectSetString(0, LABEL_TP_PROMPT, OBJPROP_FONT, "Arial");
      ObjectSetInteger(0, LABEL_TP_PROMPT, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, LABEL_TP_PROMPT, OBJPROP_SELECTABLE, false);
   }
   currentY += 20;
   
   //--- Edit box for TP input
   if(ObjectFind(0, EDIT_TP_INPUT) < 0)
   {
      ObjectCreate(0, EDIT_TP_INPUT, OBJ_EDIT, 0, 0, 0);
      ObjectSetInteger(0, EDIT_TP_INPUT, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, EDIT_TP_INPUT, OBJPROP_YDISTANCE, currentY);
      ObjectSetInteger(0, EDIT_TP_INPUT, OBJPROP_XSIZE, width);
      ObjectSetInteger(0, EDIT_TP_INPUT, OBJPROP_YSIZE, 30);
      ObjectSetString(0, EDIT_TP_INPUT, OBJPROP_TEXT, CurrentTargetTP > 0 ? DoubleToString(CurrentTargetTP, 5) : "");
      ObjectSetInteger(0, EDIT_TP_INPUT, OBJPROP_COLOR, clrBlack);
      ObjectSetInteger(0, EDIT_TP_INPUT, OBJPROP_BGCOLOR, clrWhite);
      ObjectSetInteger(0, EDIT_TP_INPUT, OBJPROP_BORDER_COLOR, clrGreen);
      ObjectSetInteger(0, EDIT_TP_INPUT, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, EDIT_TP_INPUT, OBJPROP_FONTSIZE, 10);
      ObjectSetString(0, EDIT_TP_INPUT, OBJPROP_FONT, "Arial");
      ObjectSetInteger(0, EDIT_TP_INPUT, OBJPROP_ALIGN, ALIGN_CENTER);
      ObjectSetInteger(0, EDIT_TP_INPUT, OBJPROP_READONLY, false);
      ObjectSetInteger(0, EDIT_TP_INPUT, OBJPROP_SELECTABLE, false);
   }
   currentY += 30 + spacing;
   
   //--- Set TP button
   if(ObjectFind(0, BTN_SET_TP) < 0)
   {
      ObjectCreate(0, BTN_SET_TP, OBJ_BUTTON, 0, 0, 0);
      ObjectSetInteger(0, BTN_SET_TP, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, BTN_SET_TP, OBJPROP_YDISTANCE, currentY);
      ObjectSetInteger(0, BTN_SET_TP, OBJPROP_XSIZE, width);
      ObjectSetInteger(0, BTN_SET_TP, OBJPROP_YSIZE, height);
      ObjectSetString(0, BTN_SET_TP, OBJPROP_TEXT, "SET TP");
      ObjectSetInteger(0, BTN_SET_TP, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(0, BTN_SET_TP, OBJPROP_BGCOLOR, clrGreen);
      ObjectSetInteger(0, BTN_SET_TP, OBJPROP_BORDER_COLOR, clrDarkGreen);
      ObjectSetInteger(0, BTN_SET_TP, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, BTN_SET_TP, OBJPROP_FONTSIZE, 11);
      ObjectSetString(0, BTN_SET_TP, OBJPROP_FONT, "Arial Bold");
      ObjectSetInteger(0, BTN_SET_TP, OBJPROP_SELECTABLE, false);
   }
   currentY += height + spacing + 10;
   
   //--- Label: SL Input Prompt
   if(ObjectFind(0, LABEL_SL_PROMPT) < 0)
   {
      ObjectCreate(0, LABEL_SL_PROMPT, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, LABEL_SL_PROMPT, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, LABEL_SL_PROMPT, OBJPROP_YDISTANCE, currentY);
      ObjectSetString(0, LABEL_SL_PROMPT, OBJPROP_TEXT, "Input Target SL:");
      ObjectSetInteger(0, LABEL_SL_PROMPT, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(0, LABEL_SL_PROMPT, OBJPROP_FONTSIZE, 9);
      ObjectSetString(0, LABEL_SL_PROMPT, OBJPROP_FONT, "Arial");
      ObjectSetInteger(0, LABEL_SL_PROMPT, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, LABEL_SL_PROMPT, OBJPROP_SELECTABLE, false);
   }
   currentY += 20;
   
   //--- Edit box for SL input
   if(ObjectFind(0, EDIT_SL_INPUT) < 0)
   {
      ObjectCreate(0, EDIT_SL_INPUT, OBJ_EDIT, 0, 0, 0);
      ObjectSetInteger(0, EDIT_SL_INPUT, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, EDIT_SL_INPUT, OBJPROP_YDISTANCE, currentY);
      ObjectSetInteger(0, EDIT_SL_INPUT, OBJPROP_XSIZE, width);
      ObjectSetInteger(0, EDIT_SL_INPUT, OBJPROP_YSIZE, 30);
      ObjectSetString(0, EDIT_SL_INPUT, OBJPROP_TEXT, CurrentTargetSL > 0 ? DoubleToString(CurrentTargetSL, 5) : "");
      ObjectSetInteger(0, EDIT_SL_INPUT, OBJPROP_COLOR, clrBlack);
      ObjectSetInteger(0, EDIT_SL_INPUT, OBJPROP_BGCOLOR, clrWhite);
      ObjectSetInteger(0, EDIT_SL_INPUT, OBJPROP_BORDER_COLOR, clrRed);
      ObjectSetInteger(0, EDIT_SL_INPUT, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, EDIT_SL_INPUT, OBJPROP_FONTSIZE, 10);
      ObjectSetString(0, EDIT_SL_INPUT, OBJPROP_FONT, "Arial");
      ObjectSetInteger(0, EDIT_SL_INPUT, OBJPROP_ALIGN, ALIGN_CENTER);
      ObjectSetInteger(0, EDIT_SL_INPUT, OBJPROP_READONLY, false);
      ObjectSetInteger(0, EDIT_SL_INPUT, OBJPROP_SELECTABLE, false);
   }
   currentY += 30 + spacing;
   
   //--- Set SL button
   if(ObjectFind(0, BTN_SET_SL) < 0)
   {
      ObjectCreate(0, BTN_SET_SL, OBJ_BUTTON, 0, 0, 0);
      ObjectSetInteger(0, BTN_SET_SL, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, BTN_SET_SL, OBJPROP_YDISTANCE, currentY);
      ObjectSetInteger(0, BTN_SET_SL, OBJPROP_XSIZE, width);
      ObjectSetInteger(0, BTN_SET_SL, OBJPROP_YSIZE, height);
      ObjectSetString(0, BTN_SET_SL, OBJPROP_TEXT, "SET SL");
      ObjectSetInteger(0, BTN_SET_SL, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(0, BTN_SET_SL, OBJPROP_BGCOLOR, clrOrangeRed);
      ObjectSetInteger(0, BTN_SET_SL, OBJPROP_BORDER_COLOR, clrDarkRed);
      ObjectSetInteger(0, BTN_SET_SL, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, BTN_SET_SL, OBJPROP_FONTSIZE, 11);
      ObjectSetString(0, BTN_SET_SL, OBJPROP_FONT, "Arial Bold");
      ObjectSetInteger(0, BTN_SET_SL, OBJPROP_SELECTABLE, false);
   }
   currentY += height + spacing + 10;
   
   //--- Close All button
   if(ObjectFind(0, BTN_CLOSE_ALL) < 0)
   {
      ObjectCreate(0, BTN_CLOSE_ALL, OBJ_BUTTON, 0, 0, 0);
      ObjectSetInteger(0, BTN_CLOSE_ALL, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, BTN_CLOSE_ALL, OBJPROP_YDISTANCE, currentY);
      ObjectSetInteger(0, BTN_CLOSE_ALL, OBJPROP_XSIZE, width);
      ObjectSetInteger(0, BTN_CLOSE_ALL, OBJPROP_YSIZE, height);
      ObjectSetString(0, BTN_CLOSE_ALL, OBJPROP_TEXT, "CLOSE ALL");
      ObjectSetInteger(0, BTN_CLOSE_ALL, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(0, BTN_CLOSE_ALL, OBJPROP_BGCOLOR, clrRed);
      ObjectSetInteger(0, BTN_CLOSE_ALL, OBJPROP_BORDER_COLOR, clrDarkRed);
      ObjectSetInteger(0, BTN_CLOSE_ALL, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, BTN_CLOSE_ALL, OBJPROP_FONTSIZE, 11);
      ObjectSetString(0, BTN_CLOSE_ALL, OBJPROP_FONT, "Arial Bold");
      ObjectSetInteger(0, BTN_CLOSE_ALL, OBJPROP_SELECTABLE, false);
   }
}

//+------------------------------------------------------------------+
//| Create information panel                                         |
//+------------------------------------------------------------------+
void CreatePanel()
{
   //--- Panel position (Right Upper Corner)
   int x = 10;
   int y = 30;
   int padding = 12;
   int lineHeight = 22;
   
   //--- Header Label
   if(ObjectFind(0, LABEL_HEADER) < 0)
   {
      ObjectCreate(0, LABEL_HEADER, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, LABEL_HEADER, OBJPROP_XDISTANCE, x + padding);
      ObjectSetInteger(0, LABEL_HEADER, OBJPROP_YDISTANCE, y + padding);
      ObjectSetString(0, LABEL_HEADER, OBJPROP_TEXT, "MT_MANAGER by nwf");
      ObjectSetInteger(0, LABEL_HEADER, OBJPROP_COLOR, clrDodgerBlue);
      ObjectSetInteger(0, LABEL_HEADER, OBJPROP_FONTSIZE, 11);
      ObjectSetString(0, LABEL_HEADER, OBJPROP_FONT, "Arial Bold");
      ObjectSetInteger(0, LABEL_HEADER, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
      ObjectSetInteger(0, LABEL_HEADER, OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER);
      ObjectSetInteger(0, LABEL_HEADER, OBJPROP_SELECTABLE, false);
   }
   
   //--- Symbol Label
   if(ObjectFind(0, LABEL_SYMBOL) < 0)
   {
      ObjectCreate(0, LABEL_SYMBOL, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, LABEL_SYMBOL, OBJPROP_XDISTANCE, x + padding);
      ObjectSetInteger(0, LABEL_SYMBOL, OBJPROP_YDISTANCE, y + padding + lineHeight + 8);
      ObjectSetString(0, LABEL_SYMBOL, OBJPROP_TEXT, "Symbol: " + _Symbol);
      ObjectSetInteger(0, LABEL_SYMBOL, OBJPROP_COLOR, clrWhiteSmoke);
      ObjectSetInteger(0, LABEL_SYMBOL, OBJPROP_FONTSIZE, 9);
      ObjectSetString(0, LABEL_SYMBOL, OBJPROP_FONT, "Arial");
      ObjectSetInteger(0, LABEL_SYMBOL, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
      ObjectSetInteger(0, LABEL_SYMBOL, OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER);
      ObjectSetInteger(0, LABEL_SYMBOL, OBJPROP_SELECTABLE, false);
   }
   
    //--- Timeframe Label
    if(ObjectFind(0, LABEL_TIMEFRAME) < 0)
    {
       ObjectCreate(0, LABEL_TIMEFRAME, OBJ_LABEL, 0, 0, 0);
       ObjectSetInteger(0, LABEL_TIMEFRAME, OBJPROP_XDISTANCE, x + padding);
       ObjectSetInteger(0, LABEL_TIMEFRAME, OBJPROP_YDISTANCE, y + padding + lineHeight + 28);
       ObjectSetString(0, LABEL_TIMEFRAME, OBJPROP_TEXT, "Timeframe: " + EnumToString(Period()));
       ObjectSetInteger(0, LABEL_TIMEFRAME, OBJPROP_COLOR, clrWhiteSmoke);
       ObjectSetInteger(0, LABEL_TIMEFRAME, OBJPROP_FONTSIZE, 9);
       ObjectSetString(0, LABEL_TIMEFRAME, OBJPROP_FONT, "Arial");
       ObjectSetInteger(0, LABEL_TIMEFRAME, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
       ObjectSetInteger(0, LABEL_TIMEFRAME, OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER);
       ObjectSetInteger(0, LABEL_TIMEFRAME, OBJPROP_SELECTABLE, false);
    }
    
    //--- Spread Label
    if(ObjectFind(0, LABEL_SPREAD) < 0)
    {
       ObjectCreate(0, LABEL_SPREAD, OBJ_LABEL, 0, 0, 0);
       ObjectSetInteger(0, LABEL_SPREAD, OBJPROP_XDISTANCE, x + padding);
       ObjectSetInteger(0, LABEL_SPREAD, OBJPROP_YDISTANCE, y + padding + lineHeight + 48);
       ObjectSetString(0, LABEL_SPREAD, OBJPROP_TEXT, "Spread: 0.0 pips");
       ObjectSetInteger(0, LABEL_SPREAD, OBJPROP_COLOR, clrYellow);
       ObjectSetInteger(0, LABEL_SPREAD, OBJPROP_FONTSIZE, 9);
       ObjectSetString(0, LABEL_SPREAD, OBJPROP_FONT, "Arial");
       ObjectSetInteger(0, LABEL_SPREAD, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
       ObjectSetInteger(0, LABEL_SPREAD, OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER);
       ObjectSetInteger(0, LABEL_SPREAD, OBJPROP_SELECTABLE, false);
    }
   
    //--- Countdown Label
    if(ObjectFind(0, LABEL_COUNTDOWN) < 0)
    {
       ObjectCreate(0, LABEL_COUNTDOWN, OBJ_LABEL, 0, 0, 0);
       ObjectSetInteger(0, LABEL_COUNTDOWN, OBJPROP_XDISTANCE, x + padding);
       ObjectSetInteger(0, LABEL_COUNTDOWN, OBJPROP_YDISTANCE, y + padding + lineHeight + 72);
       ObjectSetString(0, LABEL_COUNTDOWN, OBJPROP_TEXT, "Close Candle: 00:00:00");
       ObjectSetInteger(0, LABEL_COUNTDOWN, OBJPROP_COLOR, clrYellow);
       ObjectSetInteger(0, LABEL_COUNTDOWN, OBJPROP_FONTSIZE, 10);
       ObjectSetString(0, LABEL_COUNTDOWN, OBJPROP_FONT, "Arial Bold");
       ObjectSetInteger(0, LABEL_COUNTDOWN, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
       ObjectSetInteger(0, LABEL_COUNTDOWN, OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER);
       ObjectSetInteger(0, LABEL_COUNTDOWN, OBJPROP_SELECTABLE, false);
    }
   
    //--- Market Close Countdown Label
    if(ObjectFind(0, LABEL_MARKET_CLOSE) < 0)
    {
       ObjectCreate(0, LABEL_MARKET_CLOSE, OBJ_LABEL, 0, 0, 0);
       ObjectSetInteger(0, LABEL_MARKET_CLOSE, OBJPROP_XDISTANCE, x + padding);
       ObjectSetInteger(0, LABEL_MARKET_CLOSE, OBJPROP_YDISTANCE, y + padding + lineHeight + 96);
       ObjectSetString(0, LABEL_MARKET_CLOSE, OBJPROP_TEXT, "Market Close: -");
       ObjectSetInteger(0, LABEL_MARKET_CLOSE, OBJPROP_COLOR, clrOrange);
       ObjectSetInteger(0, LABEL_MARKET_CLOSE, OBJPROP_FONTSIZE, 9);
       ObjectSetString(0, LABEL_MARKET_CLOSE, OBJPROP_FONT, "Arial");
       ObjectSetInteger(0, LABEL_MARKET_CLOSE, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
       ObjectSetInteger(0, LABEL_MARKET_CLOSE, OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER);
       ObjectSetInteger(0, LABEL_MARKET_CLOSE, OBJPROP_SELECTABLE, false);
    }
   
   //--- Target TP Label
   if(ObjectFind(0, LABEL_TARGET_TP) < 0)
   {
      ObjectCreate(0, LABEL_TARGET_TP, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, LABEL_TARGET_TP, OBJPROP_XDISTANCE, x + padding);
      ObjectSetInteger(0, LABEL_TARGET_TP, OBJPROP_YDISTANCE, y + padding + lineHeight * 4 + 52);
      ObjectSetString(0, LABEL_TARGET_TP, OBJPROP_TEXT, "Target TP: -");
      ObjectSetInteger(0, LABEL_TARGET_TP, OBJPROP_COLOR, clrLime);
      ObjectSetInteger(0, LABEL_TARGET_TP, OBJPROP_FONTSIZE, 9);
      ObjectSetString(0, LABEL_TARGET_TP, OBJPROP_FONT, "Arial");
      ObjectSetInteger(0, LABEL_TARGET_TP, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
      ObjectSetInteger(0, LABEL_TARGET_TP, OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER);
      ObjectSetInteger(0, LABEL_TARGET_TP, OBJPROP_SELECTABLE, false);
   }
   
   //--- Target SL Label
   if(ObjectFind(0, LABEL_TARGET_SL) < 0)
   {
      ObjectCreate(0, LABEL_TARGET_SL, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, LABEL_TARGET_SL, OBJPROP_XDISTANCE, x + padding);
      ObjectSetInteger(0, LABEL_TARGET_SL, OBJPROP_YDISTANCE, y + padding + lineHeight * 5 + 54);
      ObjectSetString(0, LABEL_TARGET_SL, OBJPROP_TEXT, "Target SL: -");
      ObjectSetInteger(0, LABEL_TARGET_SL, OBJPROP_COLOR, clrOrange);
      ObjectSetInteger(0, LABEL_TARGET_SL, OBJPROP_FONTSIZE, 9);
      ObjectSetString(0, LABEL_TARGET_SL, OBJPROP_FONT, "Arial");
      ObjectSetInteger(0, LABEL_TARGET_SL, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
      ObjectSetInteger(0, LABEL_TARGET_SL, OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER);
      ObjectSetInteger(0, LABEL_TARGET_SL, OBJPROP_SELECTABLE, false);
   }
   
   //--- Separator
   int separatorY = y + padding + lineHeight * 6 + 64;
   
   //--- Total Positions Label
   if(ObjectFind(0, LABEL_POSITIONS) < 0)
   {
      ObjectCreate(0, LABEL_POSITIONS, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, LABEL_POSITIONS, OBJPROP_XDISTANCE, x + padding);
      ObjectSetInteger(0, LABEL_POSITIONS, OBJPROP_YDISTANCE, separatorY + 8);
      ObjectSetString(0, LABEL_POSITIONS, OBJPROP_TEXT, "Total Posisi: 0");
      ObjectSetInteger(0, LABEL_POSITIONS, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(0, LABEL_POSITIONS, OBJPROP_FONTSIZE, 10);
      ObjectSetString(0, LABEL_POSITIONS, OBJPROP_FONT, "Arial");
      ObjectSetInteger(0, LABEL_POSITIONS, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
      ObjectSetInteger(0, LABEL_POSITIONS, OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER);
      ObjectSetInteger(0, LABEL_POSITIONS, OBJPROP_SELECTABLE, false);
   }
   
   //--- Total Lots Label
   if(ObjectFind(0, LABEL_LOTS) < 0)
   {
      ObjectCreate(0, LABEL_LOTS, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, LABEL_LOTS, OBJPROP_XDISTANCE, x + padding);
      ObjectSetInteger(0, LABEL_LOTS, OBJPROP_YDISTANCE, separatorY + 8 + lineHeight);
      ObjectSetString(0, LABEL_LOTS, OBJPROP_TEXT, "Total Lot: 0.00");
      ObjectSetInteger(0, LABEL_LOTS, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(0, LABEL_LOTS, OBJPROP_FONTSIZE, 10);
      ObjectSetString(0, LABEL_LOTS, OBJPROP_FONT, "Arial");
      ObjectSetInteger(0, LABEL_LOTS, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
      ObjectSetInteger(0, LABEL_LOTS, OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER);
      ObjectSetInteger(0, LABEL_LOTS, OBJPROP_SELECTABLE, false);
   }
   
   //--- Estimated Profit Label
   if(ObjectFind(0, LABEL_PROFIT) < 0)
   {
      ObjectCreate(0, LABEL_PROFIT, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, LABEL_PROFIT, OBJPROP_XDISTANCE, x + padding);
      ObjectSetInteger(0, LABEL_PROFIT, OBJPROP_YDISTANCE, separatorY + 8 + lineHeight * 2 + 6);
      ObjectSetString(0, LABEL_PROFIT, OBJPROP_TEXT, "Estimasi Profit TP: -");
      ObjectSetInteger(0, LABEL_PROFIT, OBJPROP_COLOR, clrLime);
      ObjectSetInteger(0, LABEL_PROFIT, OBJPROP_FONTSIZE, 10);
      ObjectSetString(0, LABEL_PROFIT, OBJPROP_FONT, "Arial Bold");
      ObjectSetInteger(0, LABEL_PROFIT, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
      ObjectSetInteger(0, LABEL_PROFIT, OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER);
      ObjectSetInteger(0, LABEL_PROFIT, OBJPROP_SELECTABLE, false);
   }
   
   //--- Estimated Loss Label
   if(ObjectFind(0, LABEL_LOSS) < 0)
   {
      ObjectCreate(0, LABEL_LOSS, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, LABEL_LOSS, OBJPROP_XDISTANCE, x + padding);
      ObjectSetInteger(0, LABEL_LOSS, OBJPROP_YDISTANCE, separatorY + 8 + lineHeight * 3 + 8);
      ObjectSetString(0, LABEL_LOSS, OBJPROP_TEXT, "Estimasi Loss SL: -");
      ObjectSetInteger(0, LABEL_LOSS, OBJPROP_COLOR, clrRed);
      ObjectSetInteger(0, LABEL_LOSS, OBJPROP_FONTSIZE, 10);
      ObjectSetString(0, LABEL_LOSS, OBJPROP_FONT, "Arial Bold");
      ObjectSetInteger(0, LABEL_LOSS, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
      ObjectSetInteger(0, LABEL_LOSS, OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER);
      ObjectSetInteger(0, LABEL_LOSS, OBJPROP_SELECTABLE, false);
   }
   
   //--- Profit Pips Label
   if(ObjectFind(0, LABEL_PROFIT_PIPS) < 0)
   {
      ObjectCreate(0, LABEL_PROFIT_PIPS, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, LABEL_PROFIT_PIPS, OBJPROP_XDISTANCE, x + padding);
      ObjectSetInteger(0, LABEL_PROFIT_PIPS, OBJPROP_YDISTANCE, separatorY + 8 + lineHeight * 4 + 12);
      ObjectSetString(0, LABEL_PROFIT_PIPS, OBJPROP_TEXT, "TP Pips: -");
      ObjectSetInteger(0, LABEL_PROFIT_PIPS, OBJPROP_COLOR, clrAqua);
      ObjectSetInteger(0, LABEL_PROFIT_PIPS, OBJPROP_FONTSIZE, 9);
      ObjectSetString(0, LABEL_PROFIT_PIPS, OBJPROP_FONT, "Arial");
      ObjectSetInteger(0, LABEL_PROFIT_PIPS, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
      ObjectSetInteger(0, LABEL_PROFIT_PIPS, OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER);
      ObjectSetInteger(0, LABEL_PROFIT_PIPS, OBJPROP_SELECTABLE, false);
   }
   
   //--- Loss Pips Label
   if(ObjectFind(0, LABEL_LOSS_PIPS) < 0)
   {
      ObjectCreate(0, LABEL_LOSS_PIPS, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, LABEL_LOSS_PIPS, OBJPROP_XDISTANCE, x + padding);
      ObjectSetInteger(0, LABEL_LOSS_PIPS, OBJPROP_YDISTANCE, separatorY + 8 + lineHeight * 5 + 14);
      ObjectSetString(0, LABEL_LOSS_PIPS, OBJPROP_TEXT, "SL Pips: -");
      ObjectSetInteger(0, LABEL_LOSS_PIPS, OBJPROP_COLOR, clrOrange);
      ObjectSetInteger(0, LABEL_LOSS_PIPS, OBJPROP_FONTSIZE, 9);
      ObjectSetString(0, LABEL_LOSS_PIPS, OBJPROP_FONT, "Arial");
      ObjectSetInteger(0, LABEL_LOSS_PIPS, OBJPROP_CORNER, CORNER_RIGHT_UPPER);
      ObjectSetInteger(0, LABEL_LOSS_PIPS, OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER);
      ObjectSetInteger(0, LABEL_LOSS_PIPS, OBJPROP_SELECTABLE, false);
   }
}

//+------------------------------------------------------------------+
//| Update panel labels                                              |
//+------------------------------------------------------------------+
void UpdatePanelLabels()
{
   int digits = (int)SymbolInfoInteger(currentSymbol, SYMBOL_DIGITS);
   
    //--- Update symbol label
    ObjectSetString(0, LABEL_SYMBOL, OBJPROP_TEXT, "Symbol: " + currentSymbol);
    
    //--- Update spread label
    long spread = SymbolInfoInteger(currentSymbol, SYMBOL_SPREAD);
    double spreadPips = spread / 10.0;
    ObjectSetString(0, LABEL_SPREAD, OBJPROP_TEXT, StringFormat("Spread: %.1f pips", spreadPips));
    
    //--- Update timeframe label
    ObjectSetString(0, LABEL_TIMEFRAME, OBJPROP_TEXT, "Timeframe: " + GetTimeframeName());
   
   //--- Update countdown label
   string countdownText = GetCandleCountdown();
   ObjectSetString(0, LABEL_COUNTDOWN, OBJPROP_TEXT, countdownText);
   
   //--- Update market close countdown
   string marketCloseText = GetMarketCloseCountdown();
   ObjectSetString(0, LABEL_MARKET_CLOSE, OBJPROP_TEXT, marketCloseText);
   
   //--- Update Target TP label
   string targetTPText = "Target TP: ";
   if(CurrentTargetTP > 0)
   {
      targetTPText += DoubleToString(CurrentTargetTP, digits);
   }
   else
   {
      targetTPText += "Belum diset";
   }
   ObjectSetString(0, LABEL_TARGET_TP, OBJPROP_TEXT, targetTPText);
   
   //--- Update Target SL label
   string targetSLText = "Target SL: ";
   if(CurrentTargetSL > 0)
   {
      targetSLText += DoubleToString(CurrentTargetSL, digits);
   }
   else
   {
      targetSLText += "Belum diset";
   }
   ObjectSetString(0, LABEL_TARGET_SL, OBJPROP_TEXT, targetSLText);
   
   //--- Update positions label
   ObjectSetString(0, LABEL_POSITIONS, OBJPROP_TEXT, "Total Posisi: " + IntegerToString(totalPositions));
   
   //--- Update lots label
   ObjectSetString(0, LABEL_LOTS, OBJPROP_TEXT, "Total Lot: " + DoubleToString(totalLots, 2));
   
   //--- Update profit label
   string profitText = "Estimasi Profit TP: ";
   if(CurrentTargetTP > 0)
   {
      profitText += DoubleToString(estimatedProfit, 2) + " " + AccountInfoString(ACCOUNT_CURRENCY);
      
      //--- Change color based on profit
      if(estimatedProfit > 0)
         ObjectSetInteger(0, LABEL_PROFIT, OBJPROP_COLOR, clrLime);
      else if(estimatedProfit < 0)
         ObjectSetInteger(0, LABEL_PROFIT, OBJPROP_COLOR, clrRed);
      else
         ObjectSetInteger(0, LABEL_PROFIT, OBJPROP_COLOR, clrWhite);
   }
   else
   {
      profitText += "-";
      ObjectSetInteger(0, LABEL_PROFIT, OBJPROP_COLOR, clrWhite);
   }
   ObjectSetString(0, LABEL_PROFIT, OBJPROP_TEXT, profitText);
   
   //--- Update loss label
   string lossText = "Estimasi Loss SL: ";
   if(CurrentTargetSL > 0)
   {
      lossText += DoubleToString(estimatedLoss, 2) + " " + AccountInfoString(ACCOUNT_CURRENCY);
      
      //--- Change color based on loss
      if(estimatedLoss < 0)
         ObjectSetInteger(0, LABEL_LOSS, OBJPROP_COLOR, clrRed);
      else if(estimatedLoss > 0)
         ObjectSetInteger(0, LABEL_LOSS, OBJPROP_COLOR, clrLime);
      else
         ObjectSetInteger(0, LABEL_LOSS, OBJPROP_COLOR, clrWhite);
   }
   else
   {
      lossText += "-";
      ObjectSetInteger(0, LABEL_LOSS, OBJPROP_COLOR, clrWhite);
   }
   ObjectSetString(0, LABEL_LOSS, OBJPROP_TEXT, lossText);
   
   //--- Update profit pips label
   string profitPipsText = "TP Pips: ";
   if(CurrentTargetTP > 0)
   {
      profitPipsText += StringFormat("%.1f pips", totalProfitPips);
   }
   else
   {
      profitPipsText += "-";
   }
   ObjectSetString(0, LABEL_PROFIT_PIPS, OBJPROP_TEXT, profitPipsText);
   
   //--- Update loss pips label
   string lossPipsText = "SL Pips: ";
   if(CurrentTargetSL > 0)
   {
      lossPipsText += StringFormat("%.1f pips", totalLossPips);
   }
   else
   {
      lossPipsText += "-";
   }
   ObjectSetString(0, LABEL_LOSS_PIPS, OBJPROP_TEXT, lossPipsText);
   
   //--- Update TP edit box if CurrentTargetTP changed
   string currentTPEditText = ObjectGetString(0, EDIT_TP_INPUT, OBJPROP_TEXT);
   double currentTPEditValue = StringToDouble(currentTPEditText);
   if(CurrentTargetTP > 0 && MathAbs(currentTPEditValue - CurrentTargetTP) > 0.00001)
   {
      ObjectSetString(0, EDIT_TP_INPUT, OBJPROP_TEXT, DoubleToString(CurrentTargetTP, digits));
   }
   
   //--- Update SL edit box if CurrentTargetSL changed
   string currentSLEditText = ObjectGetString(0, EDIT_SL_INPUT, OBJPROP_TEXT);
   double currentSLEditValue = StringToDouble(currentSLEditText);
   if(CurrentTargetSL > 0 && MathAbs(currentSLEditValue - CurrentTargetSL) > 0.00001)
   {
      ObjectSetString(0, EDIT_SL_INPUT, OBJPROP_TEXT, DoubleToString(CurrentTargetSL, digits));
   }
}

//+------------------------------------------------------------------+
//| Get candle countdown string                                      |
//+------------------------------------------------------------------+
string GetCandleCountdown()
{
   datetime currentTime = TimeCurrent();
   datetime currentCandleTime = iTime(currentSymbol, Period(), 0);
   int periodSeconds = PeriodSeconds(Period());
   
   //--- Calculate time remaining for current candle
   datetime nextCandleTime = currentCandleTime + periodSeconds;
   int remainingSeconds = (int)(nextCandleTime - currentTime);
   
   //--- If negative, candle just closed, wait for new candle
   if(remainingSeconds < 0)
      remainingSeconds = 0;
   
   //--- Format as HH:MM:SS
   int hours = remainingSeconds / 3600;
   int minutes = (remainingSeconds % 3600) / 60;
   int seconds = remainingSeconds % 60;
   
   string countdownText = StringFormat("Close Candle: %02d:%02d:%02d", hours, minutes, seconds);
   
   return countdownText;
}

//+------------------------------------------------------------------+
//| Get timeframe name in readable format                            |
//+------------------------------------------------------------------+
string GetTimeframeName()
{
   switch(Period())
   {
      case PERIOD_M1:  return "M1";
      case PERIOD_M5:  return "M5";
      case PERIOD_M15: return "M15";
      case PERIOD_M30: return "M30";
      case PERIOD_H1:  return "H1";
      case PERIOD_H4:  return "H4";
      case PERIOD_D1:  return "D1";
      case PERIOD_W1:  return "W1";
      case PERIOD_MN1: return "MN1";
      default:         return EnumToString(Period());
   }
}

//+------------------------------------------------------------------+
//| Get market close/open countdown                                  |
//+------------------------------------------------------------------+
string GetMarketCloseCountdown()
{
   MqlDateTime timeStruct;
   TimeToStruct(TimeCurrent(), timeStruct);
   
   //--- If already Friday
   if(timeStruct.day_of_week == 5) // Friday
   {
      //--- Calculate time until 23:59 Friday (market close)
      datetime fridayClose;
      fridayClose = TimeCurrent() - (timeStruct.hour * 3600 + timeStruct.min * 60 + timeStruct.sec);
      fridayClose += (23 * 3600 + 59 * 60 + 59); // 23:59:59
      
      int remainingSeconds = (int)(fridayClose - TimeCurrent());
      
      if(remainingSeconds > 0)
      {
         int hours = remainingSeconds / 3600;
         int minutes = (remainingSeconds % 3600) / 60;
         
         return StringFormat("Market Close: %d jam %d menit", hours, minutes);
      }
      else
      {
         //--- Market just closed, calculate time until Monday open
         return CalculateMarketOpenCountdown();
      }
   }
   //--- If Monday to Thursday
   else if(timeStruct.day_of_week >= 1 && timeStruct.day_of_week <= 4)
   {
      //--- Calculate days until Friday
      int daysToFriday = 5 - timeStruct.day_of_week;
      int hoursToFriday = (daysToFriday * 24) + (23 - timeStruct.hour);
      
      return StringFormat("Market Close: %d hari %d jam", daysToFriday, 23 - timeStruct.hour);
   }
   //--- If Saturday or Sunday (Weekend)
   else
   {
      return CalculateMarketOpenCountdown();
   }
}

//+------------------------------------------------------------------+
//| Calculate countdown until Monday market open                     |
//+------------------------------------------------------------------+
string CalculateMarketOpenCountdown()
{
   MqlDateTime timeStruct;
   TimeToStruct(TimeCurrent(), timeStruct);
   
   //--- Calculate seconds until next Monday 00:00
   int daysUntilMonday = 0;
   
   if(timeStruct.day_of_week == 0) // Sunday
   {
      daysUntilMonday = 1;
   }
   else if(timeStruct.day_of_week == 6) // Saturday
   {
      daysUntilMonday = 2;
   }
   else if(timeStruct.day_of_week == 5) // Friday (after close)
   {
      daysUntilMonday = 3;
   }
   
   //--- Calculate next Monday midnight
   datetime mondayOpen = TimeCurrent();
   mondayOpen = mondayOpen - (timeStruct.hour * 3600 + timeStruct.min * 60 + timeStruct.sec); // Start of today
   mondayOpen += (daysUntilMonday * 86400); // Add days until Monday
   
   int remainingSeconds = (int)(mondayOpen - TimeCurrent());
   
   if(remainingSeconds > 0)
   {
      int days = remainingSeconds / 86400;
      int hours = (remainingSeconds % 86400) / 3600;
      int minutes = (remainingSeconds % 3600) / 60;
      
      if(days > 0)
      {
         return StringFormat("Market Opens: %d hari %d jam %d mnt", days, hours, minutes);
      }
      else if(hours > 0)
      {
         return StringFormat("Market Opens: %d jam %d menit", hours, minutes);
      }
      else
      {
         return StringFormat("Market Opens: %d menit", minutes);
      }
   }
   else
   {
      return "Market: Opening Soon...";
   }
}

//+------------------------------------------------------------------+
//| Check and execute auto close at time                             |
//+------------------------------------------------------------------+
void CheckAutoClose()
{
   MqlDateTime timeStruct;
   TimeToStruct(TimeCurrent(), timeStruct);
   
   //--- Parse close time
   string timeParts[];
   int parts = StringSplit(AutoCloseTime, ':', timeParts);
   
   if(parts != 2)
      return;
   
   int closeHour = (int)StringToInteger(timeParts[0]);
   int closeMinute = (int)StringToInteger(timeParts[1]);
   
   //--- Check if current time matches close time
   if(timeStruct.hour == closeHour && timeStruct.min == closeMinute)
   {
      //--- Close all positions only once per minute
      static datetime lastCloseTime = 0;
      if(TimeCurrent() - lastCloseTime > 60)
      {
         CloseAllPositions();
         lastCloseTime = TimeCurrent();
         Print("Auto Close executed at: ", TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES));
      }
   }
}

//+------------------------------------------------------------------+
//| Check market open after weekend and execute auto entry           |
//+------------------------------------------------------------------+
void CheckAutoEntry()
{
   //--- Check if entry price is set
   if(EntryPrice <= 0 || EntryLot <= 0)
      return;
   
   //--- Detect if market just opened (Monday morning)
   MqlDateTime timeStruct;
   TimeToStruct(TimeCurrent(), timeStruct);
   
   //--- Check if it's Monday and first hour of trading
   if(timeStruct.day_of_week == 1 && timeStruct.hour >= 0 && timeStruct.hour <= 3)
   {
      //--- Reset entry flag on Monday morning
      datetime currentDay = TimeCurrent() - TimeCurrent() % 86400;
      if(currentDay != lastCheckTime)
      {
         entryExecuted = false;
         lastCheckTime = currentDay;
         marketJustOpened = true;
         Print("Market detected open on Monday: ", TimeToString(TimeCurrent()));
      }
      
      //--- Check if entry not yet executed
      if(!entryExecuted && marketJustOpened)
      {
         //--- Check if price reached entry level
         double currentPrice = (EntryType == ORDER_TYPE_BUY) ? SymbolInfoDouble(currentSymbol, SYMBOL_ASK) : SymbolInfoDouble(currentSymbol, SYMBOL_BID);
         
         bool priceReached = false;
         
         if(EntryType == ORDER_TYPE_BUY && currentPrice >= EntryPrice)
         {
            priceReached = true;
         }
         else if(EntryType == ORDER_TYPE_SELL && currentPrice <= EntryPrice)
         {
            priceReached = true;
         }
         
         //--- Execute entry if price reached
         if(priceReached)
         {
            ExecuteAutoEntry();
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Execute auto entry                                               |
//+------------------------------------------------------------------+
void ExecuteAutoEntry()
{
   double point = SymbolInfoDouble(currentSymbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(currentSymbol, SYMBOL_DIGITS);
   
   //--- Calculate TP and SL
   double entryTP = 0.0;
   double entrySL = 0.0;
   
   if(EntryType == ORDER_TYPE_BUY)
   {
      entryTP = EntryPrice + (EntryTPPips * 10 * point);
      entrySL = EntryPrice - (EntrySLPips * 10 * point);
   }
   else // SELL
   {
      entryTP = EntryPrice - (EntryTPPips * 10 * point);
      entrySL = EntryPrice + (EntrySLPips * 10 * point);
   }
   
   //--- Normalize
   entryTP = NormalizeDouble(entryTP, digits);
   entrySL = NormalizeDouble(entrySL, digits);
   
   //--- Execute trade
   bool result = false;
   
   if(EntryType == ORDER_TYPE_BUY)
   {
      result = trade.Buy(EntryLot, currentSymbol, 0, entrySL, entryTP, "Auto Entry After Weekend");
   }
   else
   {
      result = trade.Sell(EntryLot, currentSymbol, 0, entrySL, entryTP, "Auto Entry After Weekend");
   }
   
   if(result)
   {
      entryExecuted = true;
      Print("Auto Entry executed: ", EnumToString(EntryType), " at price: ", EntryPrice, " | TP: ", entryTP, " | SL: ", entrySL);
   }
   else
   {
      Print("Auto Entry failed: ", trade.ResultRetcodeDescription());
   }
}
//+------------------------------------------------------------------+
