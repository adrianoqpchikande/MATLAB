f=@(c) [c(1)*(cosh((4-c(2))/c(1))-cosh((5-c(2))/c(1)))+4; c(1)*(sinh((5-c(2))/c(1))-sinh((4-c(2))/c(1)))-7];
J=@(c) [((5-c(2))*sinh((5-c(2))/c(1))-(4-c(2))*sinh((4-c(2))/c(1)))/c(1)+cosh((4-c(2))/c(1))-cosh((5-c(2))/c(1)), sinh((5-c(2))/c(1))-sinh((4-c(2))/c(1))
((4-c(2))*cosh((4-c(2))/c(1))-(5-c(2))*cosh((5-c(2))/c(1)))/c(1)-sinh((4-c(2))/c(1))+sinh((5-c(2))/c(1)), cosh((4-c(2))/c(1))-cosh((5-c(2))/c(1))];

NewtonRaphson(f,J,[1;0])