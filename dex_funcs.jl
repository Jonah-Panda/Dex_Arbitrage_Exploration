
# this only works if the data contains ints
# won't work for data which contains strings 
function extract_data(data_string::String)

    local data_parts = BigInt[]

    local split_by = 64         # should be the standard based off of abi requirements (?)
    local num_of_sections::Int = length(data_string) / split_by

    for i = 1:num_of_sections

        local _32byte_section = data_string[((i-1)*split_by)+1:split_by*i]
        local _32byte_decoded = to_big_int(_32byte_section)

        push!(data_parts, _32byte_decoded)

    end

    return data_parts

end


function get_sync_data(df::DataFrame)
    # This function creates a subset of the dex data to only include the sync data
    # for reserve values. This is needed to create the price swap curve.
    local syncs = df[df[!, :topic0].==Sync.&&df[!, :log_emitter].==unisawp_v2, :]
    select!(syncs, Not(cols_to_exclude))
    syncs.signed_at = convert_string_to_date.(syncs.signed_at)
    sort!(syncs, [:signed_at, :log_offset])
    syncs.data0 = to_big_int.(syncs.data0)
    syncs.data1 = to_big_int.(syncs.data1)
    syncs.Live_Date = offset_one(syncs.signed_at)
    return syncs
end

function filter_last_sync_in_block(Uniswap_df::DataFrame)
    # This function creates a subset of the dex data to only include the 
    # last sync value in the block
    grp = groupby(Uniswap_df, :signed_at)
    df = DataFrame(signed_at=String[],Live_Date=String[], tx_offset=Int64[], tx_hash=String[], Close=Float64[], data0=BigFloat[], data1=BigFloat[])
    for (group, subdf) in pairs(grp)
        local _date = join(collect(group), "")
        local _date2 = join(collect(group), "")
        local tx_offset = subdf.tx_offset[end]
        local tx_hash = subdf.tx_hash[end]
        local Close = subdf.CloseUSDC[end]
        local data0 = subdf.data0_real[end]
        local data1 = subdf.data1_real[end]
        push!(df, (_date, _date2, tx_offset, tx_hash, Close, data0, data1))
    end
    df.signed_at = DateTime.(df.signed_at)
    df.Live_Date = DateTime.(df.Live_Date)
    df.Live_Date = round_dateTime.(df.Live_Date)
    return df
end

function get_ETHUSD_prices(StartDate::DateTime, EndDate::DateTime)
    # Symbols of interest are ETHUSDC & ETHUSDT because they are stable coins.
    # Getting data and triming excess columns
    local ETHUSDCPriceHistory = full_prices("ETHUSDC", StartDate, EndDate)
    # println(ETHUSDCPriceHistory)
    ETHUSDCPriceHistory = select(ETHUSDCPriceHistory, [:startDate, :close])
    local colnames = ["Live_Date", "CloseUSDC"]
    rename!(ETHUSDCPriceHistory, Symbol.(colnames))

    return ETHUSDCPriceHistory
end

function get_uniswap_df(syncs::DataFrame, ETHUSDCPriceHistory::DataFrame)

    local Uniswap_with_live_prices = leftjoin(syncs, ETHUSDCPriceHistory, on=:Live_Date)

    # Uniswap_with_live_prices.SwapRate = (Uniswap_with_live_prices.data0 ./ usdc_wad) ./ (Uniswap_with_live_prices.data1 ./ weth_wad)

    select!(Uniswap_with_live_prices, (["signed_at", "tx_offset", "tx_hash", "data0", "data1", "Live_Date", "CloseUSDC"]))
    # Uniswap_with_live_prices.data0 = convert.(UInt128, Uniswap_with_live_prices.data0)
    # Uniswap_with_live_prices.data1 = convert.(UInt128, Uniswap_with_live_prices.data1)
    
    # Becasue we can only get Binance data to Sept 15th, I have deleted the rest of the dex data
    Uniswap_with_live_prices = dropmissing(Uniswap_with_live_prices, :CloseUSDC)
    Uniswap_with_live_prices.CloseUSDC = convert.(Float64, Uniswap_with_live_prices.CloseUSDC)
    Uniswap_with_live_prices.data0_real = ./(Uniswap_with_live_prices.data0, usdc_wad)
    Uniswap_with_live_prices.data1_real = ./(Uniswap_with_live_prices.data1, weth_wad)

    return Uniswap_with_live_prices
end

function get_arbs(Uniswap_with_live_prices::DataFrame)
    subset_uniswap = Uniswap_with_live_prices[!, [:data0, :data1, :Close]]

    profit_vec = Float64[]
    eth_vec = Float64[]
    usdc_vec = Float64[]

    @time begin
        for row in eachrow(subset_uniswap)
            (profit, swap_for_eth, swap_for_usdc) = SwapProfit(row.data0, row.data1, row.Close)
            push!(profit_vec, profit)
            push!(eth_vec, swap_for_eth)
            push!(usdc_vec, swap_for_usdc) 
        end
    end 

    length(profit_vec)

    Uniswap_with_live_prices.profit = profit_vec
    Uniswap_with_live_prices.eth_vec = eth_vec
    Uniswap_with_live_prices.usdc_vec = usdc_vec
    return Uniswap_with_live_prices
end 

# Loads checkmark instead of function when importing
println("Successfully loaded 'dex_funcs.jl'")