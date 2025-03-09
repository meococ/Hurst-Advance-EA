//+------------------------------------------------------------------+
//|                                 Common.mqh                        |
//|                  Copyright 2025, Trading Systems Development       |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Trading Systems Development"
#property link      "https://www.mql5.com"

// Định nghĩa MT4 MODE compatibility cho MT5
#define MODE_MAIN 0
#define MODE_SIGNAL 1
#define MODE_UPPER 1
#define MODE_LOWER 2

// Market structure definition
enum ENUM_MARKET_STRUCTURE {
   MARKET_STRONG_UPTREND,     // Strong uptrend
   MARKET_WEAK_UPTREND,       // Weak uptrend
   MARKET_RANGING,            // Ranging market
   MARKET_WEAK_DOWNTREND,     // Weak downtrend
   MARKET_STRONG_DOWNTREND,   // Strong downtrend
   MARKET_VOLATILE,           // Volatile/unstable
   MARKET_CHOPPY,             // Choppy market
   MARKET_UNKNOWN             // Unknown market
};

// Risk profile types
enum ENUM_RISK_PROFILE {
   RISK_CONSERVATIVE,         // Conservative (lower risk, higher win rate)
   RISK_BALANCED,             // Balanced (moderate risk and rewards)
   RISK_AGGRESSIVE,           // Aggressive (higher risk, faster profits)
   RISK_PROP_FIRM             // Prop firm challenge mode (strict protection)
};

// Scalping strategy modes
enum ENUM_SCALPING_MODE {
   SCALPING_ALL,             // All strategies
   SCALPING_TREND_ONLY,      // Trend following only
   SCALPING_REVERSAL_ONLY,   // Reversal only
   SCALPING_RANGE_ONLY       // Range trading only
};

// Trailing stop types
enum ENUM_TRAILING_TYPE {
   TRAILING_TYPE_FIXED,       // Fixed (pips)
   TRAILING_TYPE_ATR,         // Based on ATR
   TRAILING_TYPE_PERCENTAGE,  // Percentage of profit
   TRAILING_TYPE_PIVOT,       // Based on real pivots
   TRAILING_TYPE_ADAPTIVE     // Adaptive (market-dependent)
};

// Stop loss methods
enum ENUM_SL_TYPE {
   SL_TYPE_ATR,               // Based on ATR
   SL_TYPE_PIVOT,             // Based on pivot points
   SL_TYPE_COMBINED,          // Combined ATR and pivot
   SL_TYPE_ADAPTIVE           // Adaptive (auto-selected)
};

// Chế độ thị trường
enum ENUM_MARKET_MODE {
   MARKET_MODE_UNKNOWN,      // Không xác định
   MARKET_MODE_TRENDING,     // Xu hướng
   MARKET_MODE_RANGING,      // Đi ngang
   MARKET_MODE_VOLATILE,     // Biến động
   MARKET_MODE_REVERSAL      // Đảo chiều
};

// Loại tín hiệu
enum ENUM_SIGNAL_TYPE {
   SIGNAL_NONE,              // Không có tín hiệu
   SIGNAL_BUY,               // Tín hiệu mua
   SIGNAL_SELL               // Tín hiệu bán
};

// Chất lượng tín hiệu
enum ENUM_SIGNAL_QUALITY {
   SIGNAL_INVALID,           // Tín hiệu không hợp lệ
   SIGNAL_WEAK,              // Tín hiệu yếu
   SIGNAL_MODERATE,          // Tín hiệu trung bình
   SIGNAL_STRONG             // Tín hiệu mạnh
};

// Trading performance tracking
struct TradingPerformance {
   int totalTrades;
   int winningTrades;
   int losingTrades;
   double winRate;
   double profitFactor;
   double averageWin;
   double averageLoss;
   double expectedPayoff;
   double largestWin;
   double largestLoss;
   double maxDrawdown;
   double maxDrawdownPercent;
   datetime lastTradeTime;
   int consecutiveWins;
   int consecutiveLosses;
   double currentDrawdown;
   double dailyProfit;
   double weeklyProfit;
   double monthlyProfit;
};

// News event structure
struct NewsEvent {
   datetime time;
   string currency;
   string name;
   int impact;                            // 3 = high, 2 = medium, 1 = low
   bool processed;
};

// Hurst information structure
struct HurstInfo {
   double value;                          // Main Hurst exponent
   double trending;                       // Trending strength (0-1)
   double meanReverting;                  // Mean-reversion strength (0-1)
   double shortTermHurst;                 // Short-term Hurst
   double mediumTermHurst;                // Medium-term Hurst
   double longTermHurst;                  // Long-term Hurst
   bool isStable;                         // Stability indicator
   double sensitivity;                    // Sensitivity level
   int reliability;                       // Reliability score (0-100)
};

// Cấu trúc MultiTimeframeRSI
struct MultiTimeframeRSI {
   double current;   // RSI khung hiện tại
   double higher;    // RSI khung cao hơn
   double lower;     // RSI khung thấp hơn
   bool aligned;     // Các RSI có cùng hướng?
};

// Position tracking structure
struct PositionInfo {
   ulong ticket;
   datetime openTime;
   double openPrice;
   double lotsTotal;
   double lotsCurrent;
   double stopLoss;
   double takeProfit;
   bool isPartialClosed;
   bool isTrailingActive;
   int positionType;                      // 0 = buy, 1 = sell
   ENUM_MARKET_STRUCTURE marketStructureAtOpen;
   double hurstAtOpen;
   double riskAmount;
};

// Signal structure for strategy results
struct SignalInfo {
   bool valid;                            // Valid signal generated
   int direction;                         // 1 = buy, -1 = sell, 0 = neutral
   int strength;                          // 0-100 signal strength
   string description;                    // Signal description
   double entryPrice;                     // Suggested entry price
   double stopLoss;                       // Suggested stop loss
   double takeProfit;                     // Suggested take profit
   ENUM_MARKET_STRUCTURE marketStructure; // Current market structure
   datetime signalTime;                   // Time signal was generated
   
   // Constructor
   SignalInfo() : valid(false), direction(0), strength(0), description(""), 
                 entryPrice(0), stopLoss(0), takeProfit(0), 
                 marketStructure(MARKET_UNKNOWN), signalTime(0) {}
                 
   // Overloaded constructor
   SignalInfo(bool v, int d, int s, string desc, double price, double sl, double tp, 
             ENUM_MARKET_STRUCTURE ms, datetime t) : 
             valid(v), direction(d), strength(s), description(desc), 
             entryPrice(price), stopLoss(sl), takeProfit(tp), 
             marketStructure(ms), signalTime(t) {}
};

//+------------------------------------------------------------------+
//| Ma trận điểm tín hiệu                                            |
//+------------------------------------------------------------------+
struct SignalMatrix {
   double hurstScore;       // Điểm từ phân tích Hurst (1-10)
   double patternScore;     // Điểm từ mô hình giá (1-10)
   double trendlineScore;   // Điểm từ trendline (1-10)
   double smcScore;         // Điểm từ SMC (1-10)
   double icpScore;         // Điểm từ ICP (1-10)
   double wyckoffScore;     // Điểm từ Wyckoff (1-10)
   double rsiScore;         // Điểm từ RSI (1-10)
   
   // Trọng số - có thể điều chỉnh theo hiệu quả thực tế
   double hurstWeight;      // Mặc định 0.25 (25%)
   double patternWeight;    // Mặc định 0.20 (20%)
   double trendlineWeight;  // Mặc định 0.15 (15%)
   double smcWeight;        // Mặc định 0.15 (15%)
   double icpWeight;        // Mặc định 0.10 (10%)
   double wyckoffWeight;    // Mặc định 0.10 (10%)
   double rsiWeight;        // Mặc định 0.05 (5%)
   
   // Tổng điểm có trọng số
   double totalScore;       // Điểm cuối cùng (0-10)
   string description;      // Mô tả tín hiệu
   
   // Constructor với trọng số mặc định
   void Init() {
      hurstScore = 0;
      patternScore = 0;
      trendlineScore = 0;
      smcScore = 0;
      icpScore = 0;
      wyckoffScore = 0;
      rsiScore = 0;
      
      hurstWeight = 0.25;
      patternWeight = 0.20;
      trendlineWeight = 0.15;
      smcWeight = 0.15;
      icpWeight = 0.10;
      wyckoffWeight = 0.10;
      rsiWeight = 0.05;
      
      totalScore = 0;
      description = "";
   }
   
   // Tính tổng điểm có trọng số
   double CalculateTotalScore() {
      totalScore = hurstScore * hurstWeight +
             patternScore * patternWeight +
             trendlineScore * trendlineWeight +
             smcScore * smcWeight +
             icpScore * icpWeight +
             wyckoffScore * wyckoffWeight +
             rsiScore * rsiWeight;
             
      return totalScore;
   }
};

//+------------------------------------------------------------------+
//| Helper functions                                                  |
//+------------------------------------------------------------------+

// Convert pips to price based on symbol
double PipsToPrice(string symbol, double pips) {
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   
   double pipValue = point;
   if(digits == 3 || digits == 5)
      pipValue = point * 10;
   
   return pips * pipValue;
}

// Convert price to pips based on symbol
double PriceToPips(string symbol, double price) {
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   
   double pipValue = point;
   if(digits == 3 || digits == 5)
      pipValue = point * 10;
   
   return price / pipValue;
}

// Format double to string with specified digits
string DoubleToStrFormat(double value, int digits) {
   return DoubleToString(value, digits);
}

// Get current GMT offset
int GetGMTOffset() {
   datetime serverTime = TimeCurrent();
   MqlDateTime serverTimeStruct;
   TimeToStruct(serverTime, serverTimeStruct);
   
   datetime gmtTime = TimeGMT();
   MqlDateTime gmtTimeStruct;
   TimeToStruct(gmtTime, gmtTimeStruct);
   
   return (int)((serverTime - gmtTime) / 60);  // Return in minutes
}

// Check if current time is within trading hours
bool IsWithinTradingHours(int gmtOffset, int startHour, int endHour) {
   datetime current = TimeCurrent();
   MqlDateTime currentStruct;
   TimeToStruct(current, currentStruct);
   
   // Adjust for GMT offset
   int currentHour = (currentStruct.hour + gmtOffset) % 24;
   if(currentHour < 0) currentHour += 24;
   
   // Check if within trading hours
   if(startHour <= endHour) {
      // Normal case: startHour < endHour
      return (currentHour >= startHour && currentHour < endHour);
   } else {
      // Wrap around case: startHour > endHour (e.g., 22:00 - 05:00)
      return (currentHour >= startHour || currentHour < endHour);
   }
}

// Dashboard and UI drawing functions
void DrawDashboardPanel(int x, int y, int width, int height, color bgColor) {
   // Create panel object if not exists
   if(ObjectFind(0, "HurstDashboardPanel") < 0) {
      ObjectCreate(0, "HurstDashboardPanel", OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, "HurstDashboardPanel", OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, "HurstDashboardPanel", OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, "HurstDashboardPanel", OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, "HurstDashboardPanel", OBJPROP_XSIZE, width);
      ObjectSetInteger(0, "HurstDashboardPanel", OBJPROP_YSIZE, height);
      ObjectSetInteger(0, "HurstDashboardPanel", OBJPROP_BGCOLOR, bgColor);
      ObjectSetInteger(0, "HurstDashboardPanel", OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(0, "HurstDashboardPanel", OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, "HurstDashboardPanel", OBJPROP_BACK, false);
      ObjectSetInteger(0, "HurstDashboardPanel", OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, "HurstDashboardPanel", OBJPROP_SELECTED, false);
      ObjectSetInteger(0, "HurstDashboardPanel", OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, "HurstDashboardPanel", OBJPROP_ZORDER, 0);
   } else {
      // Update panel if exists
      ObjectSetInteger(0, "HurstDashboardPanel", OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, "HurstDashboardPanel", OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, "HurstDashboardPanel", OBJPROP_XSIZE, width);
      ObjectSetInteger(0, "HurstDashboardPanel", OBJPROP_YSIZE, height);
      ObjectSetInteger(0, "HurstDashboardPanel", OBJPROP_BGCOLOR, bgColor);
   }
}

// Add dashboard text label
void AddDashboardLabel(string name, string text, int x, int y, color textColor, string font = "Arial", int fontSize = 10) {
   if(ObjectFind(0, name) < 0) {
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
      ObjectSetString(0, name, OBJPROP_TEXT, text);
      ObjectSetString(0, name, OBJPROP_FONT, font);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
      ObjectSetInteger(0, name, OBJPROP_COLOR, textColor);
      ObjectSetInteger(0, name, OBJPROP_BACK, false);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, name, OBJPROP_ZORDER, 1);
   } else {
      ObjectSetString(0, name, OBJPROP_TEXT, text);
      ObjectSetInteger(0, name, OBJPROP_COLOR, textColor);
   }
}

// Update dashboard
void UpdateDashboard(
   double equity,
   double balance,
   double dailyPL,
   double weeklyPL,
   string marketState,
   double hurstValue,
   int positionCount,
   double totalProfit,
   color textColor,
   color valueColorGood,
   color valueColorBad,
   color valueColorNeutral
) {
   AddDashboardLabel("lbl_equity", "Equity:", 25, 25, textColor);
   AddDashboardLabel("val_equity", DoubleToString(equity, 2), 120, 25, equity >= balance ? valueColorGood : valueColorBad);
   
   AddDashboardLabel("lbl_balance", "Balance:", 25, 45, textColor);
   AddDashboardLabel("val_balance", DoubleToString(balance, 2), 120, 45, valueColorNeutral);
   
   AddDashboardLabel("lbl_daily", "Daily P/L:", 25, 65, textColor);
   AddDashboardLabel("val_daily", DoubleToString(dailyPL, 2), 120, 65, dailyPL >= 0 ? valueColorGood : valueColorBad);
   
   AddDashboardLabel("lbl_weekly", "Weekly P/L:", 25, 85, textColor);
   AddDashboardLabel("val_weekly", DoubleToString(weeklyPL, 2), 120, 85, weeklyPL >= 0 ? valueColorGood : valueColorBad);
   
   AddDashboardLabel("lbl_market", "Market:", 25, 105, textColor);
   AddDashboardLabel("val_market", marketState, 120, 105, valueColorNeutral);
   
   AddDashboardLabel("lbl_hurst", "Hurst:", 25, 125, textColor);
   
   color hurstColor = valueColorNeutral;
   if(hurstValue > 0.55) hurstColor = valueColorGood;
   else if(hurstValue < 0.45) hurstColor = valueColorBad;
   
   AddDashboardLabel("val_hurst", DoubleToString(hurstValue, 3), 120, 125, hurstColor);
   
   AddDashboardLabel("lbl_positions", "Positions:", 25, 145, textColor);
   AddDashboardLabel("val_positions", IntegerToString(positionCount), 120, 145, valueColorNeutral);
   
   AddDashboardLabel("lbl_profit", "Profit:", 25, 165, textColor);
   AddDashboardLabel("val_profit", DoubleToString(totalProfit, 2), 120, 165, totalProfit >= 0 ? valueColorGood : valueColorBad);
}

// Clean up dashboard
void CleanupDashboard() {
   ObjectDelete(0, "HurstDashboardPanel");
   ObjectDelete(0, "lbl_equity");
   ObjectDelete(0, "val_equity");
   ObjectDelete(0, "lbl_balance");
   ObjectDelete(0, "val_balance");
   ObjectDelete(0, "lbl_daily");
   ObjectDelete(0, "val_daily");
   ObjectDelete(0, "lbl_weekly");
   ObjectDelete(0, "val_weekly");
   ObjectDelete(0, "lbl_market");
   ObjectDelete(0, "val_market");
   ObjectDelete(0, "lbl_hurst");
   ObjectDelete(0, "val_hurst");
   ObjectDelete(0, "lbl_positions");
   ObjectDelete(0, "val_positions");
   ObjectDelete(0, "lbl_profit");
   ObjectDelete(0, "val_profit");
}

// Check for high impact news
bool IsHighImpactNewsTime(datetime currentTime, int minutesBefore, int minutesAfter, const NewsEvent &newsEvents[]) {
   int newsCount = ArraySize(newsEvents);
   
   for(int i = 0; i < newsCount; i++) {
      // Check if news event is high impact
      if(newsEvents[i].impact >= 3) {
         datetime newsStart = newsEvents[i].time - minutesBefore * 60;
         datetime newsEnd = newsEvents[i].time + minutesAfter * 60;
         
         // Check if current time is within news window
         if(currentTime >= newsStart && currentTime <= newsEnd) {
            return true;
         }
      }
   }
   
   return false;
}

// Load economic calendar
bool LoadEconomicCalendar(NewsEvent &newsEvents[]) {
   // This is a placeholder for loading news from a file or database
   // In a real implementation, you would connect to a news provider or load from a file
   
   ArrayResize(newsEvents, 0);
   return true;
}

// Get string representation of market structure
string MarketStructureToString(ENUM_MARKET_STRUCTURE structure) {
   switch(structure) {
      case MARKET_STRONG_UPTREND: return "Strong Uptrend";
      case MARKET_WEAK_UPTREND: return "Weak Uptrend";
      case MARKET_RANGING: return "Ranging";
      case MARKET_WEAK_DOWNTREND: return "Weak Downtrend";
      case MARKET_STRONG_DOWNTREND: return "Strong Downtrend";
      case MARKET_VOLATILE: return "Volatile";
      case MARKET_CHOPPY: return "Choppy";
      case MARKET_UNKNOWN: return "Unknown";
      default: return "Undefined";
   }
}

// Get string representation of risk profile
string RiskProfileToString(ENUM_RISK_PROFILE profile) {
   switch(profile) {
      case RISK_CONSERVATIVE: return "Conservative";
      case RISK_BALANCED: return "Balanced";
      case RISK_AGGRESSIVE: return "Aggressive";
      case RISK_PROP_FIRM: return "Prop Firm";
      default: return "Undefined";
   }
}