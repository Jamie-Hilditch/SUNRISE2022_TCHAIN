function out = isnonemptyfield(S,fieldname)
    out = isfield(S,fieldname) && ~ isempty(S.(fieldname));
end