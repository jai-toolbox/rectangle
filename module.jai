#import "Basic";

// we assume that x, y is the center of the rectangle.
Rectangle :: struct {
    x, y, w, h: float;
};

Cut_Direction ::  enum {
    /*
     * +-----------------------+
     * |     |     |     |     |
     * |     |     |     |     |
     * |  0  |  1  |  2  |  3  |
     * |     |     |     |     |
     * |     |     |     |     |
     * +-----------------------+
     */
    VERTICAL;
    /*
     * +-----------------------+
     * |           0           |
     * |-----------------------|
     * |           1           |
     * |-----------------------|
     * |           2           |
     * |-----------------------|
     * |           3           |
     * +-----------------------+
     */
    HORIZONTAL;
}

Position :: enum {
    TOP_LEFT;
    TOP_CENTER;
    TOP_RIGHT;

    CENTER_LEFT;
    CENTER;
    CENTER_RIGHT;

    BOTTOM_LEFT;
    BOTTOM_CENTER;
    BOTTOM_RIGHT;
}

create_rectangle :: (x: float, y: float, w: float, h: float, position: Position = .CENTER) -> Rectangle {
    x_offset: float = 0;
    y_offset: float = 0;
    
    if position == {
        case .TOP_LEFT;      x_offset = w/2;   y_offset = -h/2;
        case .TOP_CENTER;    x_offset = 0;     y_offset = -h/2;
        case .TOP_RIGHT;     x_offset = -w/2;  y_offset = -h/2;
        
        case .CENTER_LEFT;   x_offset = w/2;   y_offset = 0;
        case .CENTER;        x_offset = 0;     y_offset = 0;
        case .CENTER_RIGHT;  x_offset = -w/2;  y_offset = 0;
        
        case .BOTTOM_LEFT;   x_offset = w/2;   y_offset = h/2;
        case .BOTTOM_CENTER; x_offset = 0;     y_offset = h/2;
        case .BOTTOM_RIGHT;  x_offset = -w/2;  y_offset = h/2;
    }
    
    return .{x + x_offset, y + y_offset, w, h};
}

subdivide_rectangle :: (r : Rectangle, num_subdivisions: u32, cut_dir : Cut_Direction) -> [..] Rectangle {
    weights : [..] float;
    defer array_free(weights);
    for 1..num_subdivisions array_add(*weights, 1);
    return weighted_subdivide_rectangle(r, weights, cut_dir);
}

// todo padding.
weighted_subdivide_rectangle :: (rect: Rectangle, weights: [] float, cut_dir: Cut_Direction) -> [..] Rectangle {
    sub_rectangles: [..] Rectangle;
    
    total_weight: float = 0;
    for weights total_weight += it;
    
    vertical := cut_dir == .VERTICAL;
    horizontal := cut_dir == .HORIZONTAL;
    
    // initialize start position for either the x or y component
    // for horizontal cuts we start at the top of the rect
    // for vertical cuts we start at the left side
    start_position: float = ifx horizontal then rect.y + rect.h / 2 else rect.x - rect.w / 2;
    current_position := start_position;
    
    // generate subrectangles by starting from the start position and doing sequential cuts
    for weights {
        subdivision_size := (it / total_weight) * (ifx !vertical then rect.h else rect.w);
        
        subrect: Rectangle;
        subrect = rect;
        
        if horizontal {
            // create subrectangle vertically from top to bottom
            subrect.y = current_position - subdivision_size / 2;
            subrect.w = rect.w;
            subrect.h = subdivision_size;
            // update the current position for the next subdivision (move downwards)
            current_position -= subdivision_size;
        } else {
            // create subrectangle horizontally from left to right
            subrect.x = current_position + subdivision_size / 2;
            subrect.w = subdivision_size;
            subrect.h = rect.h;
            // update the current position for the next subdivision (move rightwards)
            current_position += subdivision_size;
        }
        
        array_add(*sub_rectangles, subrect);
    }
    
    return sub_rectangles;
}
