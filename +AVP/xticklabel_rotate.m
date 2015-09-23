function hText = xticklabel_rotate(XTick,rot,XTickLabel)
  set(gca,'XTick',XTick);
  set(gca,'XTickLabel',XTickLabel);
  AVP.rotateticklabel(gca,90);
end

  
