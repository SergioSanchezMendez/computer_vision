% Calcula la distancia euclidea a,b
function d = dist(a, b)    

if (nargin ~= 2)
   error('Numero de argumentos incorrecto');
end

if (size(a,1) ~= size(b,1))
   error('A y B con dimensionalidad diferente');
end

%Algebra lineal
%d = norm(A - B)

% size(a)
% size(b)

d = sqrt(sum( (a - b) .^ 2 ));

end
