/**
* Name: traffic
* Based on the internal empty template. 
* Author: minh-duc nguyen
* Tags: 
*/


model traffic


global {
	string CAR <- "car";
	string MOTO <- "motorbike";
	string OUT <- "outArea";	
	graph road_network;
	float lane_width <- 1.0;
	list<int> CHARGING_RATES <- [250, 150, 120, 60, 30, 22, 11, 7];
	float simulation_hour <- 0.0 update: simulation_hour + step/60;
}


species intersection schedules: [] skills: [intersection_skill] {}

species road  skills: [road_skill]{
	string type;
	bool oneway;
	bool s1_closed;
	bool s2_closed;
	int num_lanes <- 4;
	bool closed;
	float capacity ;
	int nb_vehicles <- length(all_agents) update: length(all_agents);
	float speed_coeff <- 1.0 min: 0.1 update: 1.0 - (nb_vehicles/ capacity);
	init {
		 capacity <- 1 + (num_lanes * shape.perimeter/3);
	}
}


species car parent: vehicle {
	string type <- CAR;
	float vehicle_length <- 4.5 #m;
	int num_lanes_occupied <-2;
	float max_speed <-rnd(50,70) #km / #h;
		
}

species motorbike parent: vehicle {
	string type <- MOTO;
	float vehicle_length <- 2.8 #m;
	int num_lanes_occupied <-1;
	float max_speed <-rnd(40,50) #km / #h;
}

species charging_station {
	int id;
	string name;
	string address;
	string operating_hours;
	
	// Port configurations
	int port_250 <- 0;
	int port_150 <- 0;
	int port_120 <- 0;
	int port_60 <- 0;
	int port_30 <- 0;
	int port_22 <- 0;
	int port_11 <- 0;
	int port_7 <- 0;
	float total_waiting_time <- 0.0;
    int vehicles_waited <- 0;
    list<vehicle> waiting_queue;
    intersection closest_intersection <- intersection closest_to self;
    
	// Modified to return average waiting time
//    float get_average_waiting_time {
//        return vehicles_waited > 0 ? total_waiting_time / vehicles_waited : 0.0;
//    }
	// Remove find_available_port and replace with get_waiting_position
    int get_waiting_position {
        return length(waiting_queue);
    }
	// Waiting queue for vehicles
//	list<electric_vehicle> waiting_queue;
	
	// Find an available charging port
	int find_available_port {
		map<int, int> port_map <- [
			250::port_250, 
			150::port_150, 
			120::port_120, 
			60::port_60, 
			30::port_30, 
			22::port_22, 
			11::port_11, 
			7::port_7
		];
		
		loop rate over: CHARGING_RATES {
			if (port_map[rate] > 0) {
				return rate;
			}
		}
//		vehicles_waited <- vehicles_waited + 1;
		return 0;
	}
//	reflex update_waiting_time {
//        if (!empty(waiting_queue)) {
//            total_waiting_time <- total_waiting_time + length(waiting_queue);
//            // Add detailed waiting time tracking per vehicle
//            ask waiting_queue {
//                self.waiting_time <- self.waiting_time + 1;
//            }
//        }
//    }
	reflex update_waiting_time {
        if (!empty(waiting_queue)) {
            float current_waiting_time <- length(waiting_queue) * step/60; // Convert to hours
            total_waiting_time <- total_waiting_time + current_waiting_time;
            
            // Update individual vehicle waiting times
            ask waiting_queue {
                waiting_time <- waiting_time + step/60;
            }
        }
    }
    
    // Get average waiting time in hours
    float get_average_waiting_time {
        return vehicles_waited > 0 ? total_waiting_time / vehicles_waited : 0.0;
    }
	
	// Occupy a port
	action occupy_port(int rate) {
		switch rate {
			match 250 { port_250 <- port_250 - 1; }
			match 150 { port_150 <- port_150 - 1; }
			match 120 { port_120 <- port_120 - 1; }
			match 60 { port_60 <- port_60 - 1; }
			match 30 { port_30 <- port_30 - 1; }
			match 22 { port_22 <- port_22 - 1; }
			match 11 { port_11 <- port_11 - 1; }
			match 7 { port_7 <- port_7 - 1; }
		}
	}
	
	// Release a port
	action release_port(int rate) {
		switch rate {
			match 250 { port_250 <- port_250 + 1; }
			match 150 { port_150 <- port_150 + 1; }
			match 120 { port_120 <- port_120 + 1; }
			match 60 { port_60 <- port_60 + 1; }
			match 30 { port_30 <- port_30 + 1; }
			match 22 { port_22 <- port_22 + 1; }
			match 11 { port_11 <- port_11 + 1; }
			match 7 { port_7 <- port_7 + 1; }
		}
	}
	
	// Add vehicle to waiting queue
	action add_to_queue(vehicle ev) {
		waiting_queue << ev;
	}
	
	// Process waiting queue
	action process_queue {
		if (!empty(waiting_queue)) {
			vehicle next_vehicle <- waiting_queue[0];
			remove next_vehicle from: waiting_queue;
			ask next_vehicle {
				do start_charging;
			}
		}
	}
	bool check_in_queue(vehicle ev)
	{
		return ev in waiting_queue;
	}
	
	
	aspect default {
		draw circle(30) color: #red;
//		draw string(name) at: location + {0, 50} color: #black;
	}
}

species vehicle skills:[driving] {
	float waiting_time <- 0.0;
	float max_waiting_time <- 30.0;
//	charging_station preferred_station;
	list<charging_station> visited_stations <- [];
	float battery_level <- 100.0;
	float battery_capacity <- nil;
	int charging_rate <- 0;
	charging_station current_station <- nil;
	list<charging_station> all_stations;
	point target_station;
	bool is_charging <- false;
	float battery_consumption_rate <- 0.1;
	float battery_charging_rate <- nil;
	float battery_threshold <- nil;

	string type;
	building target <- nil;
	building temp_target <- nil;
	charging_station target_cs;
	point shift_pt <- location ;	
	bool at_home <- false;
	list<int> peak_hours <- [7,8,9,16,17,18,19];
    list<int> business_hours <- [10,11,12,13,14,15];
    string model_name <- nil;

	
	init {
		if (model_name = 'VFe34')
		{
			battery_capacity <- 42.0;
			battery_threshold <- 8.0;
		}
		if (model_name = 'VF8')
		{
			battery_capacity <- 87.7;
			battery_threshold <- 20.0;
		}
		if (model_name = 'VF9')
		{
			battery_capacity <- 123.0;
			battery_threshold <- 20.0;
		}
		proba_respect_priorities <- 0.0;
		proba_respect_stops <- [1.0];
		proba_use_linked_road <- 0.0;

		lane_change_limit <- 2;
		linked_lane_limit <- 0; 
		location <- one_of(building).location;
	}
		// Select nearest charging station
	action select_charging_station {
//        if (empty(visited_stations)) {
        current_station <- all_stations with_min_of (each distance_to self );
//            write preferred_station;
//        } else {
//            preferred_station <- all_stations where !(each in visited_stations) 
//                                with_min_of (each distance_to self);
//        }
        
//        if (preferred_station != nil) {
//        target_station <- current_station.location;
//        target_cs <- preferred_station;
//        current_station <- preferred_station; 
        if (current_station != nil) {
        	write name + " choose charging at " + current_station.name;
        
        	do compute_path graph: road_network target: current_station.closest_intersection;
        	add current_station to: visited_stations;
        	}
        else
        {write name + 'stuck';}
//        }
    }
    action find_alternative_station {
        waiting_time <- 0.0;
        do select_charging_station;
    }
		// Start charging process
	action start_charging {
//			write name+ 'at' + current_station.name;
			try {
			int port_rate <- current_station.find_available_port();
//			write name + 'port_rate' +port_rate;
			if (port_rate > 0) {
				is_charging <- true;
				charging_rate <- port_rate;
				switch port_rate {
				match 250 { battery_charging_rate <- 2.5; }
				match 150 { battery_charging_rate <- 2; }
				match 120 { battery_charging_rate <- 1.5; }
				match 60 { battery_charging_rate <- 1.0; }
				match 30 { battery_charging_rate <- 0.525; }
				match 22 { battery_charging_rate <- 0.25; }
				match 11 { battery_charging_rate <- 0.18; }
				match 7 { battery_charging_rate <- 0.15; }
			}
				
			write name + " started charging at " + current_station.name + " with " + port_rate + "KW port";
					 }
			else {
//				write name + " waiting in queue at " + current_station.name;
				ask current_station{
					if !check_in_queue(myself){
						do add_to_queue(myself);	
						vehicles_waited <- vehicles_waited + 1;
						write myself.name + " waiting in queue at " + self.name;
					}
				}
			}
			}
			catch {
				write name + 'stuck';
			}
			}
	// Stop charging
	action stop_charging {
			ask current_station{
			do release_port(myself.charging_rate);
			}
			is_charging <- false;
			charging_rate <- 0;
			ask current_station {
			do process_queue();
			}
			write name+ " stop charging at " + current_station.name;
			current_station <- nil;
	}
		// Charging process
	reflex charging when: is_charging{
        battery_level <- min(battery_capacity, battery_level + battery_charging_rate);
        
        if (battery_level >= battery_capacity) {
            do stop_charging;
            visited_stations <- [];  // Reset visited stations after successful charge
            waiting_time <- 0.0;
        }
    }
  	action select_target_path {
	    float min_distance <- 2 #km;  // Minimum required distance
	    
	    if temp_target = nil {
	        // Keep selecting a new target until we find one that's far enough
	        bool valid_target <- false;
	        loop while: !valid_target {
	            target <- one_of(building);
	            // Calculate distance to potential target
	            float distance_to_target <- self distance_to target;
	            
	            // Check if distance meets our minimum requirement
	            if (distance_to_target >= min_distance) {
	                valid_target <- true;
	            }
	        }
	    } else {
	        target <- temp_target;
	        temp_target <- nil;
	    }
	    
	    location <- (intersection closest_to self).location;
	    do compute_path graph: road_network target: target.closest_intersection; 
	}
//	action select_target_path {
//		if temp_target =nil{
//			target <- one_of(building);
////			write 'stuck'+ target.name;
//		}
//		else
//		{
//			target <-temp_target;
//			temp_target <- nil;
//		}
//		location <- (intersection closest_to self).location;
//		do compute_path graph: road_network target: target.closest_intersection; 
//	}
//	action select_target_path {
//        if temp_target = nil {
//            // Get current hour from simulation
//            int current_hour <- int(simulation_hour mod 24);
//            
//            // Determine movement pattern based on time
//            string movement_type <- "";
//            if (current_hour in peak_hours) {
//                movement_type <- "peak";
//            } else if (current_hour in business_hours) {
//                movement_type <- "business";
//            } else {
//                movement_type <- "off_peak";
//            }
//            
//            // Select target building based on time and district
//            building selected_target;
//            
//            switch movement_type {
//                match "peak" {
//                    // During peak hours, favor business districts
//                    float rand <- rnd(0.0, 1.0);
//                    if (rand < 0.7) {
//                        // 70% chance to target business areas
//                        selected_target <- one_of(building where (each.type = "commercial"));
//                    } else if (rand < 0.9) {
//                        // 20% chance to target residential areas
//                        selected_target <- one_of(building where (each.type = "residential"));
//                    } else {
//                        // 10% chance to target other areas
//                        selected_target <- one_of(building);
//                    }
//                }
//                match "business" {
//                    // During business hours, more balanced distribution
//                    float rand <- rnd(0.0, 1.0);
//                    if (rand < 0.8) {
//                        selected_target <- one_of(building where (each.type = "commercial"));
//                    } else {
//                        selected_target <- one_of(building);
//                    }
//                }
//                match "off_peak" {
//                    // During off-peak hours, favor residential areas
//                    float rand <- rnd(0.0, 1.0);
//                    if (rand < 0.6) {
//                        selected_target <- one_of(building where (each.type = "residential"));
//                    } else {
//                        selected_target <- one_of(building);
//                    }
//                }
//            }
//            
//            target <- selected_target;
//        } else {
//            target <- temp_target;
//            temp_target <- nil;
//        }
//        
//        location <- (intersection closest_to self).location;
//        do compute_path graph: road_network target: target.closest_intersection;
//    }
//	
//	
	reflex choose_path when: final_target = nil and !is_charging{
		do select_target_path;
	}
	
	reflex move when: final_target != nil {
        if (!is_charging) {
            do drive;
            // Consume battery while moving
            battery_level <- battery_level - battery_consumption_rate;
            
            // Check if need charging
            if (battery_level < battery_threshold and current_station = nil) {
                do select_charging_station;
            }
            
            // Try to start charging if near station
//            if (current_station != nil and final_target) {
//                do start_charging;
//            }
            
           
              shift_pt <- compute_position();
        }
    }
    
    reflex charging_flag when: final_target = nil and current_station != nil and !is_charging
    {	temp_target <- target;
    	do start_charging;
    }
	
	
	point compute_position {
		// Shifts the position of the vehicle perpendicularly to the road,
		// in order to visualize different lanes
		if (current_road != nil) {
			float dist <- (road(current_road).num_lanes - current_lane -
				mean(range(num_lanes_occupied - 1)) - 0.5) * lane_width;
			if violating_oneway {
				dist <- -dist;
			}
		 	
			return location + {cos(heading + 90) * dist, sin(heading + 90) * dist};
		} else {
			return {0, 0};
		}
	}	
	
}

species building schedules: [] {
	intersection closest_intersection <- intersection closest_to self;
	string type;
	geometry pollution_perception <- shape+50;
	int pollution_index;
    
    aspect default {
        draw shape color: type = "residential" ? #blue : #orange;
    }
	
}
