function vector = force_column(vector)
    % Force shape of a 1D vector to vertical.
    if isrow(vector)
        vector = vector';
    end
end
