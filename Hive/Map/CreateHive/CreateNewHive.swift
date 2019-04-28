
// Write some function that is called when there is any error in the create hive process that displays some notification and makes sure the application stays running.


import UIKit
import Mapbox


func generatePointSet(center:[Double], radius:Double) -> [[Double]] { //
    let n = Int(ceil(1000.0*radius))
    let convert = 110.574 //km per degree lattitude
    let radiuslat = radius/convert // radius in units of lattitude
    var i = 0   // index for populating lattitudes
    let theta = (2*Double.pi)/Double(n)
    //  var pointset = [[Double]]() // initialize the point set
    var pointset = [[Double]]()
    let cosine = cos(center[1]*Double.pi/180)
    //    This populates the array with coordinate 0-(n-1)
    while i < n-1 {
        let xcord = center[0] + cos(Double(i)*theta)*radiuslat // x coordinate
        let ycord = center[1] + sin(Double(i)*theta)*radiuslat*cosine //y coordinate
        let cord = [xcord,ycord]
        pointset.append(cord)
        i += 1
    }
    // Tacks on the last coordinate as equal to the first.
    let firstpoint = [pointset[0][0], pointset[0][1]]
    pointset.append(firstpoint)
    // Return the array of coordinates.
    return pointset
}

func generateHiveData(name:String, key: String, centercoordinates:CLLocationCoordinate2D, radius:Double) -> Data {
    let center = [Double(centercoordinates.longitude),Double(centercoordinates.latitude)]
    let pointset = generatePointSet(center: center, radius: radius)
    let contents = "{\"type\": \"FeatureCollection\",\"features\": [{\"type\": \"Feature\",\"properties\": {\"key\":\"\(key)\",\"name\":\"\(name)\"},\"geometry\": {\"type\": \"Polygon\",\"coordinates\": [\(pointset.description)]}}]}"
    //color: Double, name: String, subtitle: String, center:[Double] [longitude -114, lat 51]
    //        File writing process here
    let data = Data(contents.utf8) // String into UTF8 formatting.
    return data
}


    
    
















