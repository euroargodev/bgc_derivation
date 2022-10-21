function vector = force_row(vector)
    % Force shape of a 1D vector to be horizontal.
    if iscolumn(vector)
        vector = vector';
    end
end
