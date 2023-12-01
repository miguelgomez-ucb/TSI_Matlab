% This subroutine calculates XTrack and VTrack

if on_bridge
    BridgeResponse.X_Track(1,ib) = BridgeResponse.X(1,ib-1) - 0.5 * BridgeResponse.X(3,ib-1);
    BridgeResponse.X_Track(2,ib) = -0.6 * BridgeResponse.X(3,ib-1);
    
    BridgeResponse.V_Track(1,ib) = BridgeResponse.Xdot(1,ib-1) - 0.5 * BridgeResponse.Xdot(3,ib-1);
    BridgeResponse.V_Track(2,ib) = -0.6 * BridgeResponse.Xdot(3,ib-1);

else
    %disp(BridgeResponse.X(1, ib - 1))
    BridgeResponse.X_Track(1,ib) = BridgeResponse.X(1, ib - 1) + ug(ib);
    BridgeResponse.X_Track(2,ib) = BridgeResponse.X(2, ib - 1);
    
    BridgeResponse.V_Track(1,ib) = BridgeResponse.Xdot(1, ib - 1) + ugdot(ib);
    BridgeResponse.V_Track(2,ib) = BridgeResponse.Xdot(2, ib - 1);

end


