//+------------------------------------------------------------------+
//|                            HurstAnalysis.mqh                      |
//|                  Copyright 2025, Trading Systems Development       |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Trading Systems Development"
#property link      "https://www.mql5.com"

#include <Arrays/ArrayObj.mqh>
#include <Math/Stat/Stat.mqh>
#include "../Utils/Common.mqh"

// Định nghĩa cấu trúc cache kết quả
struct HurstCacheItem {
   string symbol;
   ENUM_TIMEFRAMES timeframe;
   datetime cacheTime;
   int period;
   HurstInfo result;
};

//+------------------------------------------------------------------+
//| Structure for Hurst exponent information                         |
//+------------------------------------------------------------------+
struct HurstInfo {
   double value;          // Hurst exponent value
   datetime time;         // Time the value was calculated
   bool isTrending;       // true if market is trending (H > 0.5)
   bool isMeanReverting;  // true if market is mean reverting (H < 0.5)
   bool isRandom;         // true if market is random walk (H ≈ 0.5)
   double reliability;    // reliability of the calculation (0-100%)
   string interpretation; // textual interpretation
};

//+------------------------------------------------------------------+
//| Structure for storing Hurst in multiple timeframes               |
//+------------------------------------------------------------------+
struct MultiTimeframeHurst {
   double shortTerm;      // Short-term Hurst (200-300 candles)
   double mediumTerm;     // Medium-term Hurst (500-600 candles)
   double longTerm;       // Long-term Hurst (1000+ candles)
   datetime updateTime;   // Time of last update
   
   // Constructors
   MultiTimeframeHurst() : shortTerm(0.5), mediumTerm(0.5), longTerm(0.5), updateTime(0) {}
   MultiTimeframeHurst(double short_term, double medium_term, double long_term) 
      : shortTerm(short_term), mediumTerm(medium_term), longTerm(long_term), updateTime(TimeCurrent()) {}
};

//+------------------------------------------------------------------+
//| Structure for Hurst divergence information                       |
//+------------------------------------------------------------------+
struct HurstDivergence {
   bool exists;           // True if divergence exists
   bool isBullish;        // True if bullish divergence
   double shortTerm;      // Short-term Hurst
   double longTerm;       // Long-term Hurst
   double magnitude;      // Magnitude of divergence
   datetime time;         // Time divergence was detected
};

//+------------------------------------------------------------------+
//| Class for Hurst Exponent Calculations and Analysis               |
//+------------------------------------------------------------------+
class CHurstAnalysis {
private:
   // Hurst calculation parameters
   int m_hurstPeriod;
   double m_hurstTrendThreshold;
   double m_hurstMeanRevThreshold;
   bool m_adaptiveHurstThresholds;
   int m_hurstMinReliability;
   double m_hurstSensitivity;
   int m_hurstMinScaleSize;
   
   // Internal variables
   double m_historicalPrices[];
   int m_scales[];
   double m_scaleAvg[];
   
   // Performance metrics
   double m_calculationTimeMs;   // Thời gian xử lý mỗi lần tính toán (ms)
   int m_dataPointsProcessed;    // Số điểm dữ liệu đã xử lý
   
   // Cache system
   HurstCacheItem m_cache[];     // Mảng lưu kết quả cache
   int m_maxCacheItems;          // Số lượng tối đa các mục cache
   int m_cacheHits;              // Đếm số lần truy cập cache thành công
   int m_cacheMisses;            // Đếm số lần phải tính toán mới
   datetime m_cacheValidityPeriod; // Thời gian hiệu lực của cache (giây)
   
   // Historical Hurst data for divergence detection
   double m_hurstHistory[];      // Array to store historical Hurst values
   int m_hurstHistorySize;       // Size of history to maintain
   
   // Map of MTF Hurst by symbol
   CArrayObj m_mtfHurstMap;      // Map to store MTF Hurst by symbol
   
   // Private methods
   double CalculateRS(const double &data[], int n);
   double CalculateHurstExponent(const double &price[], int period);
   double CalculateVariance(const double &data[], int start, int end);
   double CalculateStandardDeviation(const double &data[], int start, int end);
   double LinearRegression(const double &x[], const double &y[], int n, double &intercept);
   
   // Cache methods
   bool IsCacheValid(string symbol, ENUM_TIMEFRAMES timeframe, int period);
   HurstInfo GetFromCache(string symbol, ENUM_TIMEFRAMES timeframe, int period);
   void AddToCache(string symbol, ENUM_TIMEFRAMES timeframe, int period, const HurstInfo &result);
   void CleanOldCache(datetime currentTime);
   
   // For multitimeframe analysis
   double CalculateTimeframeHurst(string symbol, ENUM_TIMEFRAMES timeframe, int bars);
   
public:
   // Constructor
   CHurstAnalysis(
      int hurstPeriod = 300,
      double hurstTrendThreshold = 0.55,
      double hurstMeanRevThreshold = 0.45,
      bool adaptiveHurstThresholds = true,
      int hurstMinReliability = 70,
      double hurstSensitivity = 1.2,
      int cacheSize = 50
   );
   
   // Destructor
   ~CHurstAnalysis();
   
   // Calculate Hurst exponent for given symbol and timeframe
   HurstInfo CalculateForSymbol(string symbol, ENUM_TIMEFRAMES timeframe, int period);
   
   // Get multiple timeframe Hurst analysis
   bool CalculateMultiTimeframe(string symbol, double &shortTermHurst, double &mediumTermHurst, double &longTermHurst);
   
   // Update parameters
   void SetParameters(
      int hurstPeriod,
      double hurstTrendThreshold,
      double hurstMeanRevThreshold,
      bool adaptiveHurstThresholds,
      int hurstMinReliability,
      double hurstSensitivity
   );
   
   // Get market regime based on Hurst value
   ENUM_MARKET_STRUCTURE GetMarketRegime(double hurstValue);
   
   // Get optimal trade direction based on Hurst exponent
   int GetOptimalTradeDirection(double hurstValue, double currentPrice, double maValue);
   
   // Get performance metrics
   double GetLastCalculationTime() const { return m_calculationTimeMs; }
   int GetDataPointsProcessed() const { return m_dataPointsProcessed; }
   double GetCacheEfficiency() const { 
      int total = m_cacheHits + m_cacheMisses;
      return total > 0 ? (double)m_cacheHits / total * 100.0 : 0; 
   }
   
   // Cache management
   void ClearCache();
   void SetCacheValidityPeriod(int seconds) { m_cacheValidityPeriod = seconds; }
   
   // Analyze Hurst divergence
   bool DetectHurstDivergence(string symbol, ENUM_TIMEFRAMES timeframe, bool &isBullish);
   
   // Check for Hurst alignment across timeframes
   bool IsHurstAligned(string symbol, ENUM_TIMEFRAMES timeframe, bool &isTrending, bool &isMeanReverting);
   
   // Get Hurst regime probability
   double GetRegimeChangeProbability(string symbol, ENUM_TIMEFRAMES timeframe);
   
   // Get recommended trading strategy based on Hurst
   string GetRecommendedStrategy(double hurstValue);
   
   // Get text interpretation of Hurst value
   string GetHurstInterpretation(double hurstValue);
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CHurstAnalysis::CHurstAnalysis(
   int hurstPeriod,
   double hurstTrendThreshold,
   double hurstMeanRevThreshold,
   bool adaptiveHurstThresholds,
   int hurstMinReliability,
   double hurstSensitivity,
   int cacheSize
) : m_hurstPeriod(hurstPeriod),
    m_hurstTrendThreshold(hurstTrendThreshold),
    m_hurstMeanRevThreshold(hurstMeanRevThreshold),
    m_adaptiveHurstThresholds(adaptiveHurstThresholds),
    m_hurstMinReliability(hurstMinReliability),
    m_hurstSensitivity(hurstSensitivity),
    m_hurstMinScaleSize(16),
    m_calculationTimeMs(0),
    m_dataPointsProcessed(0),
    m_maxCacheItems(cacheSize),
    m_cacheHits(0),
    m_cacheMisses(0),
    m_cacheValidityPeriod(3600), // 1 giờ mặc định
    m_hurstHistorySize(50)
{
   // Initialize scale values for calculation
   int scaleCount = 20;
   ArrayResize(m_scales, scaleCount);
   ArrayResize(m_scaleAvg, scaleCount);
   
   for(int i = 0; i < scaleCount; i++) {
      m_scales[i] = (int)MathPow(2, i);
   }
   
   // Initialize cache
   ArrayResize(m_cache, m_maxCacheItems);
   ArrayResize(m_hurstHistory, m_hurstHistorySize);
   ArrayInitialize(m_hurstHistory, 0.5);
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
CHurstAnalysis::~CHurstAnalysis() {
   // Clean up arrays
   ArrayFree(m_historicalPrices);
   ArrayFree(m_scales);
   ArrayFree(m_scaleAvg);
   ArrayFree(m_cache);
   ArrayFree(m_hurstHistory);
}

//+------------------------------------------------------------------+
//| Check if cache entry is valid for given parameters                |
//+------------------------------------------------------------------+
bool CHurstAnalysis::IsCacheValid(string symbol, ENUM_TIMEFRAMES timeframe, int period) {
   datetime currentTime = TimeCurrent();
   
   // Clean old cache entries first
   CleanOldCache(currentTime);
   
   // Check if result exists in cache
   for(int i = 0; i < ArraySize(m_cache); i++) {
      if(m_cache[i].symbol == symbol && 
         m_cache[i].timeframe == timeframe && 
         m_cache[i].period == period) {
         
         // Check if cache is still valid (not expired)
         if(currentTime - m_cache[i].cacheTime < m_cacheValidityPeriod) {
            m_cacheHits++;
            return true;
         }
      }
   }
   
   m_cacheMisses++;
   return false;
}

//+------------------------------------------------------------------+
//| Get Hurst result from cache                                      |
//+------------------------------------------------------------------+
HurstInfo CHurstAnalysis::GetFromCache(string symbol, ENUM_TIMEFRAMES timeframe, int period) {
   for(int i = 0; i < ArraySize(m_cache); i++) {
      if(m_cache[i].symbol == symbol && 
         m_cache[i].timeframe == timeframe && 
         m_cache[i].period == period) {
         
         return m_cache[i].result;
      }
   }
   
   // Trường hợp không tìm thấy (không nên xảy ra nếu đã kiểm tra IsCacheValid trước)
   HurstInfo emptyResult;
   return emptyResult;
}

//+------------------------------------------------------------------+
//| Add result to cache                                              |
//+------------------------------------------------------------------+
void CHurstAnalysis::AddToCache(string symbol, ENUM_TIMEFRAMES timeframe, int period, const HurstInfo &result) {
   datetime currentTime = TimeCurrent();
   
   // Tìm vị trí cache cũ nhất để thay thế
   int oldestIndex = 0;
   datetime oldestTime = currentTime;
   
   bool found = false;
   
   // Kiểm tra xem đã có entry cho symbol+timeframe+period này chưa
   for(int i = 0; i < ArraySize(m_cache); i++) {
      // Nếu tìm thấy entry trùng khớp, thay thế
      if(m_cache[i].symbol == symbol && 
         m_cache[i].timeframe == timeframe && 
         m_cache[i].period == period) {
         m_cache[i].cacheTime = currentTime;
         m_cache[i].result = result;
         found = true;
         break;
      }
      
      // Tìm entry cũ nhất
      if(m_cache[i].cacheTime < oldestTime) {
         oldestTime = m_cache[i].cacheTime;
         oldestIndex = i;
      }
   }
   
   // Nếu không tìm thấy entry trùng khớp, thay thế entry cũ nhất
   if(!found) {
      m_cache[oldestIndex].symbol = symbol;
      m_cache[oldestIndex].timeframe = timeframe;
      m_cache[oldestIndex].period = period;
      m_cache[oldestIndex].cacheTime = currentTime;
      m_cache[oldestIndex].result = result;
   }
}

//+------------------------------------------------------------------+
//| Clean expired cache entries                                      |
//+------------------------------------------------------------------+
void CHurstAnalysis::CleanOldCache(datetime currentTime) {
   // Xác định threshold thời gian cho cache hết hạn
   datetime expiryThreshold = currentTime - m_cacheValidityPeriod;
   
   for(int i = 0; i < ArraySize(m_cache); i++) {
      // Nếu cache đã cũ hơn ngưỡng, đánh dấu là không có giá trị
      if(m_cache[i].cacheTime < expiryThreshold) {
         m_cache[i].symbol = "";  // Đánh dấu là trống
      }
   }
}

//+------------------------------------------------------------------+
//| Clear all cache                                                  |
//+------------------------------------------------------------------+
void CHurstAnalysis::ClearCache() {
   for(int i = 0; i < ArraySize(m_cache); i++) {
      m_cache[i].symbol = "";
   }
   
   m_cacheHits = 0;
   m_cacheMisses = 0;
}

//+------------------------------------------------------------------+
//| Calculate Hurst exponent for given symbol and timeframe          |
//+------------------------------------------------------------------+
HurstInfo CHurstAnalysis::CalculateForSymbol(string symbol, ENUM_TIMEFRAMES timeframe, int period) {
   HurstInfo result;
   
   // Kiểm tra cache trước
   if(IsCacheValid(symbol, timeframe, period)) {
      return GetFromCache(symbol, timeframe, period);
   }
   
   uint startTime = GetTickCount();  // Đo thời gian bắt đầu
   
   // Get historical prices
   ArrayResize(m_historicalPrices, period);
   
   // Fill array with close prices
   for(int i = 0; i < period; i++) {
      m_historicalPrices[i] = iClose(symbol, timeframe, i);
   }
   
   // Reverse array to get oldest price first
   ArrayReverse(m_historicalPrices);
   
   // Calculate Hurst exponent
   result.value = CalculateHurstExponent(m_historicalPrices, period);
   
   // Calculate trending vs mean-reverting strength
   if(result.value > 0.5) {
      result.trending = (result.value - 0.5) * 2; // 0-1 scale
      result.meanReverting = 0;
   } else {
      result.trending = 0;
      result.meanReverting = (0.5 - result.value) * 2; // 0-1 scale
   }
   
   // Set stability indicator
   result.isStable = (MathAbs(result.value - 0.5) > 0.1);
   
   // Set sensitivity level
   result.sensitivity = m_hurstSensitivity;
   
   // Calculate multi-timeframe Hurst values
   CalculateMultiTimeframe(symbol, result.shortTermHurst, result.mediumTermHurst, result.longTermHurst);
   
   // Calculate reliability score (0-100)
   result.reliability = CalculateReliabilityScore(result.value, period);
   
   // Lưu metrics hiệu suất
   m_calculationTimeMs = GetTickCount() - startTime;
   m_dataPointsProcessed = period;
   
   // Cache kết quả
   AddToCache(symbol, timeframe, period, result);
   
   return result;
}

//+------------------------------------------------------------------+
//| Calculate reliability score based on data quality                |
//+------------------------------------------------------------------+
int CHurstAnalysis::CalculateReliabilityScore(double hurstValue, int period) {
   // Base reliability on period length
   int reliabilityScore = (int)MathMin(100, period / 5);
   
   // Adjust reliability based on Hurst value extremes
   if(hurstValue > 0.9 || hurstValue < 0.1) {
      reliabilityScore *= 0.7; // Extremely high/low values are less reliable
   }
   
   // Ensure minimum reliability
   return MathMax(m_hurstMinReliability, reliabilityScore);
}

//+------------------------------------------------------------------+
//| Get multiple timeframe Hurst analysis                           |
//+------------------------------------------------------------------+
bool CHurstAnalysis::CalculateMultiTimeframe(string symbol, double &shortTermHurst, double &mediumTermHurst, double &longTermHurst) {
   // Store previous values for divergence detection
   double previousShortTerm = shortTermHurst;
   double previousMediumTerm = mediumTermHurst;
   double previousLongTerm = longTermHurst;

   // Calculate Hurst for different time ranges
   shortTermHurst = CalculateTimeframeHurst(symbol, PERIOD_CURRENT, 250); // ~250 candles
   mediumTermHurst = CalculateTimeframeHurst(symbol, PERIOD_CURRENT, 500); // ~500 candles
   longTermHurst = CalculateTimeframeHurst(symbol, PERIOD_CURRENT, 1000); // ~1000 candles
   
   return true;
}

//+------------------------------------------------------------------+
//| Analyze Hurst divergence                                         |
//+------------------------------------------------------------------+
bool CHurstAnalysis::DetectHurstDivergence(string symbol, ENUM_TIMEFRAMES timeframe, bool &isBullish) {
   double shortTermHurst, mediumTermHurst, longTermHurst;
   CalculateMultiTimeframe(symbol, shortTermHurst, mediumTermHurst, longTermHurst);
   
   // Phân kỳ tăng: Hurst ngắn hạn > Hurst dài hạn
   if (shortTermHurst > longTermHurst && shortTermHurst > 0.5 && (shortTermHurst - longTermHurst > 0.15)) {
      isBullish = true;
      return true;
   }
   
   // Phân kỳ giảm: Hurst dài hạn > Hurst ngắn hạn
   if (longTermHurst > shortTermHurst && longTermHurst > 0.5 && (longTermHurst - shortTermHurst > 0.15)) {
      isBullish = false;
      return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Check for Hurst alignment across timeframes                      |
//+------------------------------------------------------------------+
bool CHurstAnalysis::IsHurstAligned(string symbol, ENUM_TIMEFRAMES timeframe, bool &isTrending, bool &isMeanReverting) {
   double shortTermHurst, mediumTermHurst, longTermHurst;
   CalculateMultiTimeframe(symbol, shortTermHurst, mediumTermHurst, longTermHurst);
   
   // Kiểm tra sự nhất quán cho xu hướng (tất cả > 0.55)
   if (shortTermHurst > 0.55 && mediumTermHurst > 0.55 && longTermHurst > 0.55) {
      isTrending = true;
      isMeanReverting = false;
      return true;
   }
   
   // Kiểm tra sự nhất quán cho đảo chiều (tất cả < 0.45)
   if (shortTermHurst < 0.45 && mediumTermHurst < 0.45 && longTermHurst < 0.45) {
      isTrending = false;
      isMeanReverting = true;
      return true;
   }
   
   // Không có sự nhất quán
   isTrending = false;
   isMeanReverting = false;
   return false;
}

//+------------------------------------------------------------------+
//| Get Hurst regime probability                                     |
//+------------------------------------------------------------------+
double CHurstAnalysis::GetRegimeChangeProbability(string symbol, ENUM_TIMEFRAMES timeframe) {
   double shortTermHurst, mediumTermHurst, longTermHurst;
   CalculateMultiTimeframe(symbol, shortTermHurst, mediumTermHurst, longTermHurst);
   
   // Tính khoảng cách giữa các Hurst
   double shortMediumDiff = MathAbs(shortTermHurst - mediumTermHurst);
   double mediumLongDiff = MathAbs(mediumTermHurst - longTermHurst);
   double shortLongDiff = MathAbs(shortTermHurst - longTermHurst);
   
   // Khoảng cách lớn giữa các Hurst cho thấy khả năng thay đổi chế độ cao
   double maxDiff = MathMax(shortMediumDiff, MathMax(mediumLongDiff, shortLongDiff));
   
   // Xác suất thay đổi chế độ từ 0-1
   if (maxDiff < 0.05) return 0.0; // Ít khả năng thay đổi
   if (maxDiff > 0.20) return 1.0; // Khả năng cao thay đổi
   
   // Tính xác suất tuyến tính từ 0.05 đến 0.20
   return (maxDiff - 0.05) / 0.15;
}

//+------------------------------------------------------------------+
//| Calculate Hurst for specific timeframe length                     |
//+------------------------------------------------------------------+
double CHurstAnalysis::CalculateTimeframeHurst(string symbol, ENUM_TIMEFRAMES timeframe, int bars) {
   // Get close prices
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   
   int copied = CopyRates(symbol, timeframe, 0, bars, rates);
   if(copied <= 0) {
      return 0.5; // Default value if data retrieval fails
   }
   
   // Extract close prices
   double closes[];
   ArrayResize(closes, copied);
   
   for(int i = 0; i < copied; i++) {
      closes[i] = rates[i].close;
   }
   
   // Calculate Hurst exponent if we have enough data
   if(copied >= MathMin(100, bars * 0.8)) {
      return CalculateHurstExponent(closes, copied);
   }
   
   return 0.5; // Default value if insufficient data
}

//+------------------------------------------------------------------+
//| Get recommended strategy based on Hurst                           |
//+------------------------------------------------------------------+
string CHurstAnalysis::GetRecommendedStrategy(double hurstValue) {
   if(IsTrendingMarket(hurstValue)) {
      return "Trend following strategies recommended. Use longer-term moving averages, ADX, and trend indicators.";
   }
   else if(IsMeanRevertingMarket(hurstValue)) {
      return "Mean reversion strategies recommended. Use oscillators like RSI, Stochastic, and counter-trend strategies.";
   }
   else {
      return "Market is in random walk phase. Reduce position sizing and wait for clearer signals.";
   }
}

//+------------------------------------------------------------------+
//| Get textual interpretation of Hurst value                         |
//+------------------------------------------------------------------+
string CHurstAnalysis::GetHurstInterpretation(double hurstValue) {
   if(hurstValue > 0.60) {
      return "Strong persistent trend. Long-lasting directional moves likely.";
   }
   else if(hurstValue > 0.55 && hurstValue <= 0.60) {
      return "Moderate trend persistence. Trend following may work well.";
   }
   else if(hurstValue >= 0.48 && hurstValue <= 0.52) {
      return "Market is following random walk. No clear statistical edge.";
   }
   else if(hurstValue >= 0.4 && hurstValue < 0.45) {
      return "Moderate mean reversion. Price tends to revert to mean.";
   }
   else if(hurstValue < 0.4) {
      return "Strong mean reversion. Anti-trend strategies recommended.";
   }
   else {
      return "Weak market regime characteristics. Monitor for changes.";
   }
}

//+------------------------------------------------------------------+
//| Check if Hurst indicates trending market                          |
//+------------------------------------------------------------------+
bool CHurstAnalysis::IsTrendingMarket(double hurstValue) {
   if(m_adaptiveHurstThresholds) {
      // Adjust threshold based on sensitivity
      double threshold = m_hurstTrendThreshold * (1.0 - (m_hurstSensitivity - 1.0) * 0.05);
      return hurstValue > threshold;
   }
   
   return hurstValue > m_hurstTrendThreshold;
}

//+------------------------------------------------------------------+
//| Check if Hurst indicates mean reverting market                    |
//+------------------------------------------------------------------+
bool CHurstAnalysis::IsMeanRevertingMarket(double hurstValue) {
   if(m_adaptiveHurstThresholds) {
      // Adjust threshold based on sensitivity
      double threshold = m_hurstMeanRevThreshold * (1.0 + (m_hurstSensitivity - 1.0) * 0.05);
      return hurstValue < threshold;
   }
   
   return hurstValue < m_hurstMeanRevThreshold;
} 