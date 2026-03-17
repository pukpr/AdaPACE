package Pace.Surrogates is
   ------------------------------------------------------------
   -- SURROGATES -- Pool of surrogate tasks for asynch delivery
   ------------------------------------------------------------
   -- Redispatched to the INPUT primitive from Pace.Msg
   pragma Elaborate_Body;

   procedure Input (Obj : in Msg'Class);


   generic
      type Async_Msg is new Msg with private;
   package Asynchronous is
      ------------------------------------------------------
      -- ASYNCHRONOUS -- Asynchronous remote procedure call
      ------------------------------------------------------
      -- Instantiated with ASYNC_MSG type which is then redipatched
      --  to the correct recipient through the SURROGATE task.
      -- It gets sent to the INPUT primitive from Pace.Msg

      task Surrogate is
         entry Input (Obj : in Async_Msg);
      end Surrogate;

   end Asynchronous;

   ------------------------------------------------------------------------------
   -- $id: pace-surrogates.ads,v 1.1 09/16/2002 18:18:57 pukitepa Exp $
   ------------------------------------------------------------------------------
end Pace.Surrogates;
