function form2xml(F) {
  var S = "";
  var setIndex;
  var formName = F.name;
  for (I=0; I < F.length; I++) {
    if (F.elements[I].name == "set") {
      setIndex = I;
    } else {
      if (F.elements[I].type == "checkbox") {
        if (F.elements[I].checked) {
          S = S + "<"+ F.elements[I].name +">" + F.elements[I].value + "</"+ F.elements[I].name +">";
        }
      } else if (F.elements[I].type != "submit") {
        S = S + "<"+ F.elements[I].name +">" + F.elements[I].value + "</"+ F.elements[I].name +">";
      }
    }
  }
  F.elements[setIndex].value = "<" + formName + ">" + S + "</" + formName + ">";
  return 1;
}


function form2prolog(F) {
  var S = F.elements[0].name + "(" + F.elements[0].value + ")";
  for (I=1; I < F.length; I++) {
     S = S + "," + F.elements[I].name + "(" + F.elements[I].value + ")";
  }
  F.set.value = F.name + "([" + S + "])";
  return 1;
}
