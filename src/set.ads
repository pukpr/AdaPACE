generic
   type Elements is (<>);
package Set is
   type Members is array (Integer range <>) of Elements;
   function Member (E : Elements; M : Members) return Boolean;

   -- $Id: set.ads,v 1.2 2004/09/20 22:14:26 pukitepa Exp $

end Set;
