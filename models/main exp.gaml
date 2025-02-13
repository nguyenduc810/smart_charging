/**
* Name: mainexp
* Based on the internal empty template. 
* Author: minh-duc nguyen
* Tags: 
*/


model mainexp
import 'traffic.gaml'
//import 'charging_station.gaml'

/* Insert your model definition here */

global {
	float step <- 1.0 #m;
	list<road> open_roads;
	float player_size_GAMA <- 20.0;

	//Colors and icons
	string images_dir <- "../images/";
	list<rgb> pal <- palette([#green, #yellow, #orange, #red]);
	map<rgb, string>
	legends <- [color_inner_building::"District Buildings", color_outer_building::"Outer Buildings", color_road::"Roads", color_closed::"Closed Roads", color_lake::"Rivers & lakes", color_car::"Cars", color_moto::"Motorbikes"];
	rgb color_car <- #blue;
	rgb color_moto <- #cyan;
	rgb color_road <- #black;
	rgb color_closed <- #mediumpurple;
	rgb color_inner_building <- #green;
	rgb color_outer_building <- rgb(60, 60, 60);
	rgb color_lake <- rgb(165, 199, 238, 255);
	// Initialization 
	string resources_dir <- "../includes/";

	// Load shapefiles
//	shape_file buildings_shape_file <- shape_file(resources_dir + "buildings.shp");
//	shape_file houses_shape_file <- shape_file(resources_dir + "building_house.shp");
//    shape_file commercial_shape_file <- shape_file(resources_dir + "building_commercial.shp");
//	shape_file badinh <- shape_file(resources_dir + "building_Ba_Dinh.shp");
//    shape_file BTL <- shape_file(resources_dir + "building_Bac_Tu_Liem.shp");
//    shape_file caugiay <- shape_file(resources_dir + "building_Cau_Giay.shp");
//    shape_file dongda <- shape_file(resources_dir + "building_Dong_Da.shp");
    shape_file HBT <- shape_file(resources_dir + "building_HBT.shp");
//    shape_file hoankiem <- shape_file(resources_dir + "building_Hoan_Kiem.shp");
    shape_file hoangmai <- shape_file(resources_dir + "building_Hoang_Mai.shp");
//    shape_file longbien <- shape_file(resources_dir + "building_Long_Bien.shp");
//    shape_file NTL <- shape_file(resources_dir + "building_Nam_Tu_Liem.shp");
//    shape_file tayho <- shape_file(resources_dir + "building_Tay_Ho.shp");
//    shape_file thanhxuan <- shape_file(resources_dir + "building_Thanh_Xuan.shp");
//    shape_file district  <- shape_file(resources_dir + "building_district.shp");
	
    
//	geometry shape <- envelope(buildings_shape_file);
	geometry shape <- envelope(HBT);
//	geometry shape <- envelope(commercial_shape_file);
	shape_file charging_stations_shape <- shape_file(resources_dir+"charging_station_HM_HBT.shp");
//	file charging_stations_csv <- csv_file(resources_dir + "charging_stations_v1.csv", ",");
	// Charging rates
	list<int> CHARGING_RATES <- [250, 150, 120, 60, 30, 22, 11, 7];
	list <charging_station> all_stations <- [];
	 // Add time tracking
    float simulation_hour <- 0.0 update: simulation_hour + step/60;
    int day_counter <- 1;
    string csv_file_path <- "../includes/station_statistics.csv";
	

	init {
//		create road from: shape_file(resources_dir + "roads_Thanh_Xuan_clean.shp");
//		create road from: shape_file(resources_dir + "roads_Tay_Ho_clean.shp");
//		create road from: shape_file(resources_dir + "roads_Nam_Tu_Liem.shp");
//		create road from: shape_file(resources_dir + "roads_Long_Bien.shp");
		create road from: shape_file(resources_dir + "roads_Hoang_Mai_clean.shp");
//		create road from: shape_file(resources_dir + "roads_Hoan_Kiem_clean.shp");
		create road from: shape_file(resources_dir + "roads_HBT_clean.shp");
//		create road from: shape_file(resources_dir + "roads_Dong_Da_clean.shp");
//		create road from: shape_file(resources_dir + "roads_Cau_Giay.shp");
//		create road from: shape_file(resources_dir + "roads_Bac_Tu_Liem.shp");
//		create road from: shape_file(resources_dir + "roads_Ba_Dinh_clean.shp");

		loop r over: road {
			if (!r.oneway) {
				create road with: (shape: polyline(reverse(r.shape.points)), name: r.name, type: r.type, s1_closed: r.s1_closed, s2_closed: r.s2_closed);
			} 
		string headers <- "Day,Station ID,Average Waiting Time,Vehicles Served\n";
        save headers to: csv_file_path type: "text";
		}
			
		
//		create building from: shape_file(buildings_shape_file);
//		create building from: houses_shape_file with: [type::"residential"];
//        create building from: commercial_shape_file with: [type::"commercial"];
//		create building from: badinh;
//		create building from: BTL;
//		create building from: caugiay;
//		create building from: dongda;
		create building from: HBT;
//		create building from: hoankiem;
		create building from: hoangmai;
//		create building from: longbien;
//		create building from: NTL;
//		create building from: thanhxuan;
//		create building from: tayho;

			
		ask road {
			agent ag <- building closest_to self;
			float dist <- ag = nil ? 8.0 : max(min( ag distance_to self - 5.0, 8.0), 2.0);
			num_lanes <- int(dist / lane_width);
			 capacity <- 1 + (num_lanes * shape.perimeter/3);
		}
		
		
		int cars <- 200;
//		int motos <- 1000;
		do load_charging_stations();
//		loop cs over: all_stations{
//			write cs.name;
//			write cs.port_250;
//			write cs.port_150;
//			write cs.port_120;
//			write cs.port_60;
//			write cs.port_30;
//			write cs.port_22;
//			write cs.port_11;
//			write cs.port_7;
//		}
		do update_road_scenario(0);
		create car number: 500 with: (all_stations: all_stations,battery_level: 0.2*42.0, model_name: 'VFe34')  ; 
		create car number: 500 with: (all_stations: all_stations,battery_level: 0.2*87.7, model_name: 'VF8')  ; 
		create car number: 500 with: (all_stations: all_stations,battery_level: 0.2*123.0, model_name: 'VF9')  ; 
//		create car number: 500 with: (all_stations: all_stations,battery_level: 0.5*42.0, model_name: 'VFe34')  ; 
//		create car number: 500 with: (all_stations: all_stations,battery_level: 0.5*87.7, model_name: 'VF8')  ; 
//		create car number: 500 with: (all_stations: all_stations,battery_level: 0.5*123.0, model_name: 'VF9')  ; 
//		create car number: 500 with: (all_stations: all_stations,battery_level: 0.8*42.0, model_name: 'VFe34')  ; 
//		create car number: 500 with: (all_stations: all_stations,battery_level: 0.8*87.7, model_name: 'VF8')  ; 
//		create car number: 500 with: (all_stations: all_stations,battery_level: 0.8*123.0, model_name: 'VF9')  ; 
//		do update_car_population(cars);
//		do update_motorbike_population( motos);
		
	}
	
	    reflex export_daily_statistics when: simulation_hour >= (day_counter * 24) {
        // Prepare data for all stations
	        loop station over: all_stations {
	            // Get statistics
	            float avg_waiting_time <- station.get_average_waiting_time();
	            int vehicles_served <- station.vehicles_waited;
	            
	            // Create CSV line
	            string line <- ""+day_counter+","+station.id+","+avg_waiting_time+","+vehicles_served+"\n";
	            
	            // Append to CSV file
	            save line to: csv_file_path type: "text" rewrite: false;
	            
	            // Reset station counters for next day
	            ask station {
	                total_waiting_time <- 0.0;
	                vehicles_waited <- 0;
	            }
	        }
	        
	        // Increment day counter
	        day_counter <- day_counter + 1;
    }
	action load_charging_stations {
		create charging_station from: charging_stations_shape with: [
			id:: int(read("station_id")),
			name::string(read("Name")),
            address::string(read("Address")),
            operating_hours::string(read("Operating_Hours")),
			port_250::int(read("Ports_250KW")),
            port_150::int(read("Ports_150KW")),
            port_120::int(read("Ports_120KW")),
            port_60::int(read("Ports_60KW")),
            port_30::int(read("Ports_30KW")),
            port_22::int(read("Ports_22KW")),
            port_11::int(read("Ports_11KW")),
            port_7::int(read("Ports_7KW"))
		];
		loop cs over: list(charging_station){
			if (cs.port_250>0 or cs.port_150>0 or cs.port_120>0 or cs.port_60 >0 or cs.port_30 >0 or cs.port_22 >0 or cs.port_11 >0 or cs.port_7 >0)
			{add cs to: all_stations;}
			}
//		all_stations <- list(charging_station);
	}

//	 action load_charging_stations {
//        // Create charging stations from CSV
//        create charging_station from: charging_stations_csv with: [
//            name::string(read("Name")),
//            address::string(read("Address")),
//            operating_hours::string(read("Operating_Hours")),
//            // Convert string values to integers for ports
//            port_250::int(read("Ports_250KW")),
//            port_150::int(read("Ports_150KW")),
//            port_120::int(read("Ports_120KW")),
//            port_60::int(read("Ports_60KW")),
//            port_30::int(read("Ports_30KW")),
//            port_22::int(read("Ports_22KW")),
//            port_11::int(read("Ports_11KW")),
//            port_7::int(read("Ports_7KW")),
//            // Add location coordinates
//            location::{float(read("Longitude")), float(read("Latitude"))}
//        ];
//        all_stations <- list(charging_station);
//    }

	action update_motorbike_population (int new_number) {
		int delta <- length(motorbike) - new_number;
		if (delta > 0) {
			ask delta among motorbike {
				do unregister;
				do die;
			}

		} else if (delta < 0) {
			create motorbike number: -delta ;
		}

	}
	action update_car_population (int new_number) {
		create car number: new_number with: (all_stations: all_stations)  ;

	}
	
	action update_road_scenario (int scenario) {
		open_roads <- scenario = 1 ? road where !each.s1_closed : (scenario = 2 ? road where !each.s2_closed : list(road));
		// Change the display of roads
		list<road> closed_roads <- road - open_roads;
		ask open_roads {
			closed <- false;
		}

		ask closed_roads {
			closed <- true;
		}

		ask agents of_generic_species vehicle {
			do unregister;
			if (current_road in closed_roads) {
				do die;
			}

		}

		ask building {
			closest_intersection <- nil;
		}
		ask charging_station {
			closest_intersection <- nil;
		}
		

		ask intersection {
			do die;
		}

		graph g <- as_edge_graph(open_roads);
		loop pt over: g.vertices {
			create intersection with: (shape: pt);
		}

		ask building {
			closest_intersection <- intersection closest_to self;
		}
//		ask agents of_generic_species charging_station  {
//			closest_intersection <- intersection closest_to self;
//		}
		ask charging_station  {
			closest_intersection <- intersection closest_to self;
		}
		ask road {
			vehicle_ordering <- nil;
		}
		//build the graph from the roads and intersections
		road_network <- as_driving_graph(open_roads, intersection) with_shortest_path_algorithm #FloydWarshall;
		//geometry road_geometry <- union(open_roads accumulate (each.shape));
		ask agents of_generic_species vehicle {
			do select_target_path;
		} 
	}

	
	} 

experiment "Run me" autorun: true  {
	float maximum_cycle_duration <- 0.15;
	output {
		display Computer virtual: false type: 3d toolbar: true background: #gray axes: false {
			species road {
				draw self.shape + 4 color: closed ? color_closed : color_road;
			}

			agents "Vehicles" value: (agents of_generic_species(vehicle)) where (each.current_road != nil) {
				draw rectangle(vehicle_length * 10, lane_width * num_lanes_occupied * 10) at: shift_pt color: type = CAR ? color_car : color_moto rotate: self.heading;
			}

			species building {
				draw self.shape color: type = OUT ? color_outer_building : (color_inner_building);
			}
			species building;
			species charging_station;

//			mesh cell triangulation: true transparency: 0.4 smooth: 3 above: 5 color: pal position: {0, 0, 0.01} visible: true;
		}

	}

}