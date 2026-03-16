# Bottom Information Boxes Fix

## Issue
The bottom 3 information boxes in diagrams 2 and 3 were not displaying when exporting to images from draw.io, even though they displayed correctly in the IDE.

## Root Cause
1. **Page Height Constraints**: The boxes were positioned very close to the bottom edge of the page, which caused export issues
2. **Missing Visibility Attribute**: The boxes didn't have explicit `visible="1"` attributes

## Diagrams Affected
- **Diagram 2 (Primary Ireland)**: `2-primary-ireland-v2.drawio`
  - Key Metrics box (y=1180)
  - Cross-Region Replication box (y=1180)
  - Health Status box (y=1180)

- **Diagram 3 (DR London)**: `3-dr-london-v2.drawio`
  - DR Key Metrics box (y=1120)
  - Health Status box (y=1120)
  - Replication Status box (y=1120)

## Fixes Applied

### 1. Increased Page Height
**Diagram 2:**
- Changed from `pageHeight="1400"` to `pageHeight="1500"` (+100px padding)
- Bottom boxes end at y=1330, now have 170px buffer

**Diagram 3:**
- Changed from `pageHeight="1300"` to `pageHeight="1400"` (+100px padding)
- Bottom boxes end at y=1240, now have 160px buffer

### 2. Added Explicit Visibility
Added `visible="1"` attribute to all three bottom boxes in both diagrams:

**Diagram 2:**
```xml
<mxCell id="metrics" ... visible="1">
<mxCell id="replication" ... visible="1">
<mxCell id="health" ... visible="1">
```

**Diagram 3:**
```xml
<mxCell id="metrics" ... visible="1">
<mxCell id="health" ... visible="1">
<mxCell id="replication" ... visible="1">
```

## Testing
After applying these fixes, when you export diagrams 2 and 3 to images from draw.io:
1. Open the diagram in draw.io
2. Go to File → Export As → PNG (or SVG/JPEG)
3. The bottom three information boxes should now be included in the export

## Box Details

### Diagram 2 Bottom Boxes
1. **Key Metrics** (Left, Gray)
   - Resources: ~850
   - Monthly Cost: $3,000-$5,000
   - Availability: 99.99%
   - RTO/RPO metrics

2. **Cross-Region Replication** (Middle, Blue)
   - Aurora Global Database
   - S3 CRR
   - ECR Replication
   - DynamoDB Global Tables

3. **Health Status** (Right, Green)
   - 🟢 PRIMARY ACTIVE
   - All services running
   - Serving production traffic

### Diagram 3 Bottom Boxes
1. **DR Key Metrics** (Left, Gray)
   - Resources: ~600
   - Cost: Pilot vs Warm
   - RTO/RPO: < 10 min / < 1 sec
   - Auto-Failover: ENABLED

2. **Health Status** (Middle, Orange)
   - 🔴 DR STANDBY
   - Minimal services
   - Ready to scale
   - Monitoring primary

3. **Replication Status** (Right, Green)
   - Aurora lag < 1s
   - S3 CRR Active
   - DynamoDB synced
   - Secrets replicated

## Comparison with Diagram 1
**Diagram 1** has `pageHeight="1080"` but its bottom box extends to y=1125 (beyond page). Draw.io allows this overflow, but diagrams 2 and 3 needed explicit fixes for reliable export.

## Date
Fixed: 2024-01-15
