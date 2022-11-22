# Code that Jaime provided us in Tutorial 2 

using Binance, Dates

function getBinanceKlineDataframe(symbol; startDateTime=nothing, endDateTime=nothing, interval="1m")
    klines = Binance.getKlines(symbol; startDateTime=startDateTime, endDateTime=endDateTime, interval=interval)
    result = hcat(map(z -> map(x -> typeof(x) == String ? parse(Float64, x) : x, z), klines)...)'

    if size(result, 2) == 0
        return nothing
    end

    symbolColumnData = map(x -> symbol, collect(1:size(result, 1)))
    df = DataFrame([symbolColumnData, Dates.unix2datetime.(result[:, 1] / 1000), result[:, 2], result[:, 3], result[:, 4], result[:, 5], result[:, 6], result[:, 8], Dates.unix2datetime.(result[:, 7] / 1000), result[:, 9], result[:, 10], result[:, 11]], [:symbol, :startDate, :open, :high, :low, :close, :volume, :quoteAVolume, :endDate, :trades, :tbBaseAVolume, :tbQuoteAVolume])
end

function full_prices(symbol, start_date, final_date)

    local _500_mins = Dates.Minute(500)
    local end_date = start_date + _500_mins

    local prices_df = getBinanceKlineDataframe(symbol; startDateTime=start_date, endDateTime=end_date)

    while end_date < final_date
        start_date = end_date
        end_date = start_date + Dates.Minute(500)
        # Dates.Minute(500)
        local temp = getBinanceKlineDataframe(symbol; startDateTime=start_date, endDateTime=end_date)
        try
            prices_df = vcat(prices_df, temp)
        catch
            println("Error at time range: ", start_date, ", ", end_date)
            println(temp)
            exit(-1)
        end

    end

    return prices_df
end


# Loads checkmark instead of function when importing
println("Successfully loaded 'binance_functions.jl'")