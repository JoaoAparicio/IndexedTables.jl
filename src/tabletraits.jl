using TableTraits
using TableTraitsUtils

TableTraits.isiterable(x::NDSparse) = true
TableTraits.isiterabletable(x::NDSparse) = true

function TableTraits.getiterator(source::S) where {S <: NDSparse}
    return rows(source)
end

function _array_factory(t,rows)
    if isa(t, TypeVar)
        return Array{Any}(rows)
    elseif t <: DataValue
        return DataValueArray{eltype(t)}(rows)
    else
        return Array{t}(rows)
    end
end

function NDSparse(x; idxcols::Union{Void,Vector{Symbol}}=nothing, datacols::Union{Void,Vector{Symbol}}=nothing)
    if isiterabletable(x)
        iter = getiterator(x)

        source_colnames = TableTraits.column_names(iter)

        if idxcols==nothing && datacols==nothing
            idxcols = source_colnames[1:end-1]
            datacols = [source_colnames[end]]
        elseif idxcols==nothing
            idxcols = setdiff(source_colnames,datacols)
        elseif datacols==nothing
            datacols = setdiff(source_colnames, idxcols)
        end

        if length(setdiff(idxcols, source_colnames))>0
            error("Unknown idxcol")
        end

        if length(setdiff(datacols, source_colnames))>0
            error("Unknown datacol")
        end

        source_data, source_names = TableTraitsUtils.create_columns_from_iterabletable(x, array_factory=_array_factory)

        idxcols_indices = [findfirst(source_colnames,i) for i in idxcols]
        datacols_indices = [findfirst(source_colnames,i) for i in datacols]

        idx_storage = Columns(source_data[idxcols_indices]..., names=source_colnames[idxcols_indices])
        data_storage = Columns(source_data[datacols_indices]..., names=source_colnames[datacols_indices])

        return NDSparse(idx_storage, data_storage)
    elseif idxcols==nothing && datacols==nothing
        return convert(NDSparse, x)
    else
        throw(ArgumentError("x cannot be turned into an NDSparse."))
    end
end

function table(rows::AbstractArray{T}; copy=false, kwargs...) where {T<:Union{Tup, Pair}}
    convert(NextTable, collect_columns(rows); copy=false, kwargs...)
end

function table(iter; copy=false, kwargs...)
    if TableTraits.isiterable(iter)
        convert(NextTable, collect_columns(getiterator(iter)); copy=false, kwargs...)
    else
        throw(ArgumentError("iter cannot be turned into a NextTable."))
    end
end
